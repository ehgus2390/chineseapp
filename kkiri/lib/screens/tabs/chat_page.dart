// lib/screens/tabs/chat_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../state/app_state.dart';
import '../chat/chat_room_screen.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  void _showEmailOnlySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email login required to send messages.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final authState = context.watch<AppState>();

    final user = authState.user;
    final uid = user?.uid;
    final isEmailUser = user != null && !user.isAnonymous;

    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Login required to participate in chat',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (chat.isInRoom) {
      if (!isEmailUser) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Email login required to send messages.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
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
                    if (!isEmailUser) {
                      _showEmailOnlySnackBar(context);
                      return;
                    }
                    if (uid == null) return;
                    await chat.joinRandomRoom(uid);
                  },
          ),
        ],
      ),
    );
  }
}
