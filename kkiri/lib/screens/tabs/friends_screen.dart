import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friends_provider.dart';
import '../../utils/matching_rules.dart';
import '../chat/chat_room_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final idCtrl = TextEditingController();

  @override
  void dispose() {
    idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final friendsProv = context.watch<FriendsProvider>();
    final chatProv = context.read<ChatProvider>();

    final myUid = auth.currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
        builder: (_, mySnap) {
          if (!mySnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final myData = mySnap.data?.data() ?? {};
          final myGender = myData['gender'] as String?;
          final myCountry = myData['country'] as String?;

          return Column(
            children: [
              // ───────────────── 친구 추가 UI ─────────────────
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

              const Divider(),

              // ✅ 여기 Expanded 위치가 깨져서 에러났던 것: Column children 안에 넣어야 함
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: friendsProv.myFriendsStream(myUid),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final friends = snap.data!;
                    if (friends.isEmpty) {
                      return const Center(child: Text('친구가 없습니다.'));
                    }

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (_, i) {
                        final f = friends[i];
                        final peerId = f['uid'] as String? ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                            (f['photoUrl'] != null) ? NetworkImage(f['photoUrl']) : null,
                            child: (f['photoUrl'] == null) ? const Icon(Icons.person) : null,
                          ),
                          title: Text(f['displayName'] ?? peerId),
                          subtitle: Text('@${f['searchId'] ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () async {
                              // ✅ 1:1 채팅 인증 필요
                              if (!auth.requireVerified(context, '1:1 채팅')) return;

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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
