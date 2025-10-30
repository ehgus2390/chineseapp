import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final idCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final friendsProv = context.watch<FriendsProvider>();
    final chatProv = context.read<ChatProvider>();
    final myUid = auth.currentUser?.uid;
    if (myUid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(
                    hintText: '친구 아이디(searchId)를 입력하세요',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final keyword = idCtrl.text.trim();
                  if (keyword.isEmpty) return;
                  final user = await friendsProv.findUserBySearchId(keyword);
                  if (user == null || user['uid'] == myUid) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용자를 찾을 수 없습니다.')));
                    return;
                  }
                  await friendsProv.addFriendBoth(myUid, user['uid']);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user['displayName']} 추가됨')));
                },
                child: const Text('추가'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: friendsProv.myFriendsStream(myUid),
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final friends = snap.data!;
              if (friends.isEmpty) return const Center(child: Text('친구가 없습니다.'));
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (_, i) {
                  final f = friends[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: f['photoUrl'] != null ? NetworkImage(f['photoUrl']) : null,
                      child: f['photoUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(f['displayName'] ?? f['uid']),
                    subtitle: Text('@${f['searchId'] ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () async {
                        final chatId = await chatProv.createOrGetChatId(myUid, f['uid']);
                        if (!mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(peerId: peerId)));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
