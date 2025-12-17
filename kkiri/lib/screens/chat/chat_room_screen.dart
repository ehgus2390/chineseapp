import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? peerPhoto;

  const ChatRoomScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerPhoto,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final myId =
          context.read<AuthProvider>().currentUser?.uid;
      if (myId == null) return;

      await context.read<ChatProvider>().resetUnread(
        myUid: myId,
        peerUid: widget.peerId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final myId = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chat.messageStream(myId, widget.peerId),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg = docs[i].data();
                    final isMe =
                        msg['senderId'] == myId;

                    final ts =
                    msg['createdAt'] as Timestamp?;
                    final time = ts != null
                        ? DateFormat('HH:mm')
                        .format(ts.toDate())
                        : '';

                    return ChatBubble(
                      text: msg['text'] ?? '',
                      isMe: isMe,
                      photoUrl: isMe
                          ? auth.currentUser?.photoURL
                          : widget.peerPhoto,
                      time: time,
                    );
                  },
                );
              },
            ),
          ),
          _input(chat, myId),
        ],
      ),
    );
  }

  Widget _input(ChatProvider chat, String myId) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(chat, myId),
              decoration:
              const InputDecoration(hintText: '메시지 입력'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _send(chat, myId),
          ),
        ],
      ),
    );
  }

  Future<void> _send(ChatProvider chat, String myId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await chat.sendMessage(
      senderId: myId,
      receiverId: widget.peerId,
      text: text,
    );
    _controller.clear();
  }
}
