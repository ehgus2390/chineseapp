import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n_extensions.dart';
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
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      final myId = auth.currentUser?.uid;
      if (myId != null) {
        await chat.createOrGetChatId(myId, widget.peerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final myId = auth.currentUser!.uid;
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (widget.peerPhoto != null &&
                  widget.peerPhoto!.startsWith('http'))
                  ? NetworkImage(widget.peerPhoto!)
                  : const AssetImage('assets/images/logo.png')
              as ImageProvider,
            ),
            const SizedBox(width: 8),
            Text(widget.peerName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chat.messageStream(myId, widget.peerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = docs[i].data();
                    final isMe = msg['senderId'] == myId;

                    final ts = msg['createdAt'] as Timestamp?;
                    final time = ts != null
                        ? DateFormat('HH:mm').format(ts.toDate())
                        : '';

                    return ChatBubble(
                      text: msg['text'] ?? '',
                      isMe: isMe,
                      photoUrl: isMe ? auth.currentUser?.photoURL : widget.peerPhoto,
                      time: time,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(chat, myId, l10n.chatHint, colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider chat, String myId, String hint, Color accent) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(chat, myId),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.send, color: accent),
              onPressed: () => _send(chat, myId),
            ),
          ],
        ),
      ),
    );
  }

  void _send(ChatProvider chat, String myId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await chat.sendMessage(
      senderId: myId,
      receiverId: widget.peerId,
      text: text,
    );
    _controller.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
