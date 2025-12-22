import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/community_service.dart';

class UniversityCommunityFeedScreen extends StatelessWidget {
  const UniversityCommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;

    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = CommunityProvider(service: CommunityService());
        if (uid != null) {
          provider.loadForUser(uid);
        }
        return provider;
      },
      child: const _UniversityCommunityFeedView(),
    );
  }
}

class _UniversityCommunityFeedView extends StatelessWidget {
  const _UniversityCommunityFeedView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<CommunityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.universityCommunityTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _CommunityHeader(
              subtitle: t.universityCommunitySubtitle,
              communityStream: provider.universityCommunityStream(),
            ),
          ),
          Expanded(
            child: _CommunityPostList(
              isLoading: provider.isLoading,
              error: provider.error,
              hasCommunity: provider.hasUniversityCommunity,
              emptyMessage: t.universityCommunityEmpty,
              missingMessage: t.universityCommunityMissing,
              postsStream: provider.universityPostsStream(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({
    required this.subtitle,
    required this.communityStream,
  });

  final String subtitle;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> communityStream;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: communityStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] as String?) ?? t.homeCampusFallback;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_city, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityPostList extends StatelessWidget {
  const _CommunityPostList({
    required this.isLoading,
    required this.error,
    required this.hasCommunity,
    required this.emptyMessage,
    required this.missingMessage,
    required this.postsStream,
  });

  final bool isLoading;
  final String? error;
  final bool hasCommunity;
  final String emptyMessage;
  final String missingMessage;
  final Stream<QuerySnapshot<Map<String, dynamic>>> postsStream;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasCommunity) {
      return Center(child: Text(missingMessage));
    }

    if (error != null) {
      return Center(child: Text(missingMessage));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: postsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final content = data['content'] as String? ?? '';
            final createdAt = data['createdAt'] as Timestamp?;
            final likes = _safeInt(data['likesCount']);
            final comments = _safeInt(data['commentsCount']);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.anonymous,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _relativeTime(t, createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.favorite_border, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble_outline, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      comments.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _safeInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _relativeTime(AppLocalizations t, Timestamp? timestamp) {
    if (timestamp == null) return t.justNow;
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());

    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
    return t.daysAgo(diff.inDays);
  }
}
