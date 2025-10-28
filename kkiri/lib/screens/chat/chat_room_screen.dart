import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../services/storage_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  const ChatRoomScreen({super.key, required this.chatId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ctrl = TextEditingController();
  final _picker = ImagePicker();
  File? _previewImage;
  bool _sending = false;

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    setState(() => _previewImage = File(x.path));
  }

  Future<void> _sendImage() async {
    if (_previewImage == null) return;
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    final storage = StorageService();
    final chatProv = context.read<ChatProvider>();

    setState(() => _sending = true);
    try {
      final url = await storage.uploadChatImage(
        chatId: widget.chatId,
        senderUid: uid,
        file: _previewImage!,
      );
      await chatProv.sendImageMessage(widget.chatId, uid, url);
      setState(() => _previewImage = null);
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final chatProv = context.read<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('채팅')),
      body: Column(
        children: [
          if (_previewImage != null)
            Container(
              color: Colors.black12,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_previewImage!, width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('이미지 전송 준비…', style: TextStyle(color: Colors.grey[800]))),
                  TextButton(
                    onPressed: _sending ? null : () => setState(() => _previewImage = null),
                    child: const Text('취소'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _sendImage,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('전송'),
                  )
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatProv.messagesStream(widget.chatId),
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snap.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i].data();
                    final isMe = m['senderId'] == uid;
                    final time = (m['createdAt'] as Timestamp?)?.toDate();

                    return ChatBubble(
                      isMe: isMe,
                      text: m['text'],
                      imageUrl: m['imageUrl'],
                      time: time,
                      avatarUrl: isMe ? null : null, // 필요 시 상대방 photoUrl 전달
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage,
                  tooltip: '사진 첨부',
                ),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      hintText: '메시지 입력...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = ctrl.text.trim();
                    if (text.isEmpty) return;
                    await chatProv.sendTextMessage(widget.chatId, uid, text);
                    ctrl.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
