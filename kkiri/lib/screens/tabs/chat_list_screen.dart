import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProv = context.watch<ChatProvider>();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chatProv.myChatRooms(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data!.docs;
        if (rooms.isEmpty) {
          return const Center(child: Text('채팅방이 없습니다.'));
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final roomDoc = rooms[index];
            final data = roomDoc.data();

            final lastMsg = data['lastMessage'] ?? '(대화를 시작해보세요)';
            final users = List<String>.from(data['users'] ?? []);
            final otherUser =
            users.firstWhere((u) => u != uid, orElse: () => '익명');

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(otherUser),
              subtitle: Text(lastMsg),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      peerId: otherUser,
                      peerName: otherUser, // 나중에 displayName으로 바꿔도 됨
                      peerPhoto: null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
