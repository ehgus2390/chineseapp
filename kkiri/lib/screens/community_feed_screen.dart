import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/community_profile_repository.dart';
import '../state/app_state.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityProfileRepository _profileRepository =
      CommunityProfileRepository();

  String? _school;
  String? _region;

  @override
  void initState() {
    super.initState();
    _loadProfileContext();
  }

  Future<void> _loadProfileContext() async {
    final uid = context.read<AppState>().user?.uid;
    if (uid == null || uid.isEmpty) return;

    final data = await _profileRepository.getProfileData(uid);
    if (!mounted) return;

    final school = data?['school'];
    final region = data?['region'];

    setState(() {
      _school = school is String && school.trim().isNotEmpty ? school : null;
      _region = region is String && region.trim().isNotEmpty ? region : null;
    });
  }

  Query<Map<String, dynamic>> _queryForTab(int index) {
    final CollectionReference<Map<String, dynamic>> posts = FirebaseFirestore
        .instance
        .collection('community')
        .doc('apps')
        .collection('main')
        .collection('posts');

    switch (index) {
      case 1:
        if (_school == null) {
          return posts.where(FieldPath.documentId, isEqualTo: '__empty__');
        }
        return posts
            .where('school', isEqualTo: _school)
            .orderBy('createdAt', descending: true);
      case 2:
        if (_region == null) {
          return posts.where(FieldPath.documentId, isEqualTo: '__empty__');
        }
        return posts
            .where('region', isEqualTo: _region)
            .orderBy('createdAt', descending: true);
      case 3:
        return posts
            .where('school', isEqualTo: '')
            .where('region', isEqualTo: '')
            .orderBy('createdAt', descending: true);
      case 0:
      default:
        return posts.orderBy('createdAt', descending: true);
    }
  }

  String _formatCreatedAt(dynamic value) {
    if (value is! Timestamp) return '-';
    final d = value.toDate();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd $hh:$min';
  }

  void _openCreatePostPlaceholder(BuildContext context) {
    // TODO: Navigate to CreatePostScreen when it is implemented.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CreatePostScreen is not implemented yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'My School'),
              Tab(text: 'Region'),
              Tab(text: 'Free'),
            ],
          ),
        ),
        body: TabBarView(
          children: List.generate(4, (index) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _queryForTab(index).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load posts.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No posts yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final content = data['content'];
                    final likeCount = data['likeCount'];
                    final commentCount = data['commentCount'];
                    final createdAt = data['createdAt'];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content is String ? content : '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                    'Likes ${likeCount is num ? likeCount : 0}'),
                                const SizedBox(width: 12),
                                Text(
                                  'Comments ${commentCount is num ? commentCount : 0}',
                                ),
                                const Spacer(),
                                Text(
                                  _formatCreatedAt(createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openCreatePostPlaceholder(context),
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}
