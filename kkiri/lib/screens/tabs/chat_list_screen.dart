import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/interest_options.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/match_provider.dart';
import '../chat/chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProv = context.watch<ChatProvider>();
    final l10n = context.l10n;
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatListTitle)),
      body: Column(
        children: [
          _RecommendedStrip(uid: uid, chatProv: chatProv),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatProv.myChatRooms(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rooms = snapshot.data!.docs;
                if (rooms.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.chatEmptyState, textAlign: TextAlign.center),
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
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(l10n.profileTitle),
                          );
                        }

                        final user = userSnapshot.data!.data() ?? <String, dynamic>{};
                        final displayName = user['displayName'] as String? ?? l10n.profileTitle;
                        final photoUrl = user['photoUrl'] as String?;
                        final lastMessage = data['lastMessage'] as String? ?? l10n.recommendedStartChat;
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
            ),
          ),
        ],
      ),
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

class _RecommendedStrip extends StatelessWidget {
  const _RecommendedStrip({required this.uid, required this.chatProv});

  final String uid;
  final ChatProvider chatProv;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loc = context.watch<LocationProvider>();
    final matchProv = context.watch<MatchProvider>();

    if (loc.position == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _RecommendationCard(
          title: l10n.recommendedNearbyTitle,
          subtitle: l10n.pleaseShareLocation,
          child: Text(l10n.recommendedEmpty, textAlign: TextAlign.center),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: matchProv.userStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 190, child: Center(child: CircularProgressIndicator()));
        }
        final meData = snapshot.data!.data() ?? <String, dynamic>{};
        final liked = Set<String>.from(meData['likesSent'] ?? []);
        final passed = Set<String>.from(meData['passes'] ?? []);
        final matches = Set<String>.from(meData['matches'] ?? []);
        final myInterests = Set<String>.from(meData['interests'] ?? []);

        return StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          stream: loc.nearbyUsersStream(uid, 5),
          builder: (context, nearbySnapshot) {
            if (!nearbySnapshot.hasData) {
              return const SizedBox(height: 190, child: Center(child: CircularProgressIndicator()));
            }
            final candidates = nearbySnapshot.data!
                .where((doc) => doc.id != uid)
                .where((doc) => doc.data() != null)
                .where((doc) => !liked.contains(doc.id))
                .where((doc) => !passed.contains(doc.id))
                .map(UserModel.fromFirestore)
                .toList()
              ..sort((a, b) {
                final aScore = _sharedInterestScore(a.interests ?? [], myInterests);
                final bScore = _sharedInterestScore(b.interests ?? [], myInterests);
                return bScore.compareTo(aScore);
              });

            if (candidates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _RecommendationCard(
                  title: '${l10n.recommendedNearbyTitle} · ${l10n.recDistanceTag}',
                  subtitle: l10n.recommendedNearbySubtitle,
                  child: Text(l10n.noCandidates, textAlign: TextAlign.center),
                ),
              );
            }

            return SizedBox(
              height: 210,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('${l10n.recommendedNearbyTitle} · ${l10n.recDistanceTag}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: candidates.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final user = candidates[index];
                        return _RecommendationTile(
                          user: user,
                          myInterests: myInterests,
                          onTap: () async {
                            await chatProv.createOrGetChatId(uid, user.uid);
                            final navigator = Navigator.of(context);
                            if (!navigator.mounted) return;
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  peerId: user.uid,
                                  peerName: user.displayName ?? 'Friend',
                                  peerPhoto: user.photoUrl,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.user,
    required this.myInterests,
    required this.onTap,
  });

  final UserModel user;
  final Set<String> myInterests;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayInterests = _interestLabels(user.interests ?? <String>[], l10n);
    final sharedCount = _sharedInterestScore(user.interests ?? [], myInterests);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFECF4FF), Color(0xFFE7F7EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.displayName ?? 'Friend',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sharedCount > 0)
            Text(
              '${sharedCount}× ${l10n.interestLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Wrap(
            spacing: 6,
            runSpacing: -6,
            children: displayInterests.take(3).map((interest) {
              return Chip(
                label: Text(interest),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: const Icon(Icons.favorite, size: 14),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onTap, child: Text(l10n.recommendedStartChat)),
          ),
        ],
      ),
    );
  }
}

int _sharedInterestScore(List<String> interests, Set<String> myInterests) {
  if (interests.isEmpty || myInterests.isEmpty) return 0;
  return interests.where(myInterests.contains).length;
}

List<String> _interestLabels(List<String> interests, AppLocalizations l10n) {
  return interests.map((id) {
    if (kInterestOptionIds.contains(id)) {
      return l10n.interestLabelText(id);
    }
    return id;
  }).toList();
}
