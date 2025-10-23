import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';

class UserProfilePopup extends StatelessWidget {
  final String uid;
  final String? displayName;
  final String? photoUrl;

  const UserProfilePopup({
    super.key,
    required this.uid,
    this.displayName,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 12),
          Text(displayName ?? '사용자', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('대화 시작하기'),
            onPressed: () async {
              final myUid = auth.currentUser!.uid;
              if (myUid == uid) return;
              final chatId = await chatProv.createOrGetChatId(myUid, uid);
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(chatId: chatId)));
            },
          ),
        ],
      ),
    );
  }
}
