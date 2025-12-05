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
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('채팅방이 없습니다.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final users = (d['users'] as List?)?.cast<String>() ?? const <String>[];
            final counterpartId = users.firstWhere(
              (id) => id != uid,
              orElse: () => users.isNotEmpty ? users.first : '알 수 없는 사용자',
            );
            return ListTile(
              title: Text((d['lastMessage'] as String?) ?? '(대화 시작해보세요)'),
              subtitle: Text(users.isEmpty ? '참여자 정보 없음' : counterpartId),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatRoomScreen(chatId: docs[i].id)),
                );
              },
            );
          },
        );
      },
    );
  }
}
