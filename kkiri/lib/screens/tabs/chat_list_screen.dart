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
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data!.docs;
        if (rooms.isEmpty) {
          return const Center(child: Text('채팅방이 없습니다.'));
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (_, i) {
            final data = rooms[i].data();
            final users = List<String>.from(data['users'] ?? []);
            if (users.isEmpty) return const SizedBox.shrink();

            final peerId = users.firstWhere((u) => u != uid, orElse: () => '');

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(peerId.isEmpty ? 'Unknown' : peerId),
              subtitle: Text((data['lastMessage'] as String?) ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (!auth.requireVerified(context, '1:1 채팅')) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(
                      peerId: peerId,
                      peerName: peerId,
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
