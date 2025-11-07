import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/match_provider.dart';
import '../chat/chat_room_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final matchProv = context.watch<MatchProvider>();
    final chatProv = context.read<ChatProvider>();
    final myUid = auth.currentUser?.uid;

    if (myUid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭된 인연'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: matchProv.matchesStream(myUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!;
          if (matches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '아직 매칭된 사람이 없어요. 발견 탭에서 마음에 드는 사람에게 좋아요를 보내보세요!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final match = matches[index];
              final photoUrl = match['photoUrl'] as String?;
              final displayName = match['displayName'] as String? ?? '알 수 없는 사용자';
              final bio = match['bio'] as String? ?? '소개글이 아직 없어요.';
              final interests = (match['interests'] as List?)?.cast<String>() ?? <String>[];

              return ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                  backgroundColor: Colors.pinkAccent,
                ),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (interests.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: -4,
                          children: interests
                              .take(3)
                              .map((interest) => Chip(
                                    label: Text(interest),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.pinkAccent),
                  tooltip: '채팅 시작',
                  onPressed: () async {
                    final otherUid = match['uid'] as String;
                    await chatProv.createOrGetChatId(myUid, otherUid);
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
