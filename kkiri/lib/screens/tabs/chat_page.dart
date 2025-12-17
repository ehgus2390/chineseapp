import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();

    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    if (chat.isInRoom) {
      return const ChatRoomScreen();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '근처 오픈채팅에 참여해 보세요',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: chat.isJoining
                ? const Text('입장 중...')
                : const Text('랜덤 오픈채팅 참여'),
            onPressed: chat.isJoining
                ? null
                : () async {
              await chat.joinRandomRoom(uid);
            },
          ),
        ],
      ),
    );
  }
}
