import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  /// 두 UID를 항상 같은 순서로 정렬하여 roomId 생성
  String _roomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myId = auth.currentUser?.uid;

    if (myId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("채팅"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: context.read<ChatProvider>().myChatRooms(myId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const Center(child: Text('대화 목록이 없습니다.'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, i) {
              final chat = chats[i];
              final data = chat.data();

              // 상대방 UID 추출
              final users = List<String>.from(data['users']);
              final peerId = users.firstWhere((id) => id != myId);

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(peerId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox.shrink();
                  }
                  final user = userSnap.data!.data();
                  if (user == null) return const SizedBox.shrink();

                  final name = user['displayName'] ?? '익명 사용자';
                  final photo = user['photoUrl'];
                  final lastMsg = data['lastMessage'] ?? '';
                  final time = data['updatedAt'] != null
                      ? (data['updatedAt'] as Timestamp)
                      .toDate()
                      .toLocal()
                      .toString()
                      .substring(11, 16)
                      : '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (photo != null && photo.toString().startsWith('http'))
                          ? NetworkImage(photo)
                          : const AssetImage('assets/images/logo.png') as ImageProvider,
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      if (!auth.isEmailVerified) {
                        auth.ensureEmailVerified(
                          context,
                          message:
                              '이 기능을 사용하려면 이메일 인증이 필요합니다. 프로필에서 이메일 인증을 완료해주세요.',
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            peerId: peerId,
                            peerName: name,
                            peerPhoto: photo,
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
      ),
    );
  }
}
