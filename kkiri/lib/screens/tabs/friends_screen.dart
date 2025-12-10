import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_room_screen.dart';
import '../../utils/matching_rules.dart';

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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
      builder: (_, mySnap) {
        if (!mySnap.hasData) return const Center(child: CircularProgressIndicator());
        final myData = mySnap.data?.data() ?? {};
        final myGender = myData['gender'] as String?;
        final myCountry = myData['country'] as String?;

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
                    onPressed: myGender == null || myCountry == null
                        ? null
                        : () async {
                            final keyword = idCtrl.text.trim();
                            if (keyword.isEmpty) return;
                            final user = await friendsProv.findUserBySearchId(keyword);
                            if (user == null || user['uid'] == myUid) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용자를 찾을 수 없습니다.')));
                              return;
                            }

                            final otherGender = user['gender'] as String?;
                            final otherCountry = user['country'] as String?;
                            if (!isTargetMatch(myGender, myCountry, otherGender, otherCountry)) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('상대방의 성별/국적이 조건에 맞지 않습니다.')),
                              );
                              return;
                            }

                            await friendsProv.addFriendBoth(myUid, user['uid']);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${user['displayName'] ?? '사용자'} 추가됨')),
                            );
                          },
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
            if (myGender == null || myCountry == null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('성별과 국적을 프로필에서 설정하면 친구를 추가할 수 있습니다.'),
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
                        final peerId = f['uid'] as String;
                        await chatProv.createOrGetChatId(myUid, peerId);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              peerId: peerId,
                              peerName: f['displayName'] ?? peerId,
                              peerPhoto: f['photoUrl'] as String?,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
