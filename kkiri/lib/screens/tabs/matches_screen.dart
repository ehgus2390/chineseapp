import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/interest_options.dart';
import '../../l10n/l10n_extensions.dart';
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
    final l10n = context.l10n;
    final myUid = auth.currentUser?.uid;

    if (myUid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matchesTitle),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: matchProv.matchesStream(myUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!;
          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.matchesEmpty, textAlign: TextAlign.center),
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
              final displayName = match['displayName'] as String? ?? l10n.profileTitle;
              final bio = match['bio'] as String? ?? l10n.bioHint;
              final interests = (match['interests'] as List?)?.cast<String>() ?? <String>[];
              final interestLabels = interests
                  .map((interest) =>
                      kInterestOptionIds.contains(interest) ? context.l10n.interestLabelText(interest) : interest)
                  .toList();

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
                    if (interestLabels.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: -4,
                          children: interestLabels
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
                  tooltip: l10n.recommendedStartChat,
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
