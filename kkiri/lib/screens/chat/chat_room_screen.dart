import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/auth_guard.dart';
import '../../widgets/chat_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인 후 이용 가능한 기능입니다'),
        ),
      );
    }

    final myId = user.uid;
    final myName = user.displayName ?? '익명';

    return Scaffold(
      appBar: AppBar(
        title: const Text('오픈 채팅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await chat.leaveRoom(myId);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chat.currentRoomMessages(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? const [];

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg = docs[i].data();
                    final isMe = msg['userId'] == myId;

                    final ts = msg['createdAt'] as Timestamp?;
                    final time = ts != null
                        ? DateFormat('HH:mm').format(ts.toDate())
                        : '';

                    return ChatBubble(
                      text: msg['text'] ?? '',
                      isMe: isMe,
                      time: time,
                      photoUrl: null,
                    );
                  },
                );
              },
            ),
          ),
          _input(chat, myId, myName),
        ],
      ),
    );
  }

  Widget _input(ChatProvider chat, String myId, String myName) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '메시지 입력',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _send(chat, myId, myName),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _send(chat, myId, myName),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(
      ChatProvider chat,
      String myId,
      String myName,
      ) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!await requireEmailLogin(context, 'Chat')) return;

    await chat.sendRoomMessage(
      uid: myId,
      text: text,
      displayName: myName,
      profileAllowed: false,
    );

    _controller.clear();

    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
