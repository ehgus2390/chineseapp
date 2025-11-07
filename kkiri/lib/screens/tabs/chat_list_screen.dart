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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('매칭된 사람과의 대화가 아직 없어요. 좋아요를 보내 매칭을 만들어보세요!'),
            ),
          );
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final data = rooms[index].data();
            final members = List<String>.from(data['users'] ?? []);
            final otherUid = members.firstWhere((m) => m != uid, orElse: () => uid);

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(otherUid).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('알 수 없는 사용자'),
                  );
                }

                final user = userSnapshot.data!.data() ?? <String, dynamic>{};
                final displayName = user['displayName'] as String? ?? '알 수 없는 사용자';
                final photoUrl = user['photoUrl'] as String?;
                final lastMessage = data['lastMessage'] as String? ?? '대화를 시작해보세요!';
                final updatedAt = data['updatedAt'] as Timestamp?;
                final subtitle = updatedAt != null
                    ? '${lastMessage}\n${_formatTimestamp(updatedAt)}'
                    : lastMessage;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(displayName),
                  subtitle: Text(subtitle),
                  isThreeLine: true,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    if (!navigator.mounted) return;
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          peerId: otherUid,
                          peerName: displayName,
                          peerPhoto: photoUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

String _formatTimestamp(Timestamp ts) {
  final date = ts.toDate();
  final now = DateTime.now();
  if (date.difference(DateTime(now.year, now.month, now.day)).inDays == 0) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  return '${date.month}.${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
