import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../services/community_post_repository.dart';
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
  final CommunityPostRepository _postRepository = CommunityPostRepository();

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
        .doc('root')
        .collection('posts');

    switch (index) {
      case 4:
        return posts.orderBy('likeCount', descending: true).limit(20);
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

  Future<void> _openCreatePost(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const CreatePostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().user?.uid;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'My School'),
              Tab(text: 'Region'),
              Tab(text: 'Free'),
              Tab(text: 'Hot'),
            ],
          ),
        ),
        body: TabBarView(
          children: List.generate(5, (index) {
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
                    final text = data['text'] ?? data['content'];
                    final likeCount = data['likeCount'];
                    final commentCount = data['commentCount'];
                    final createdAt = data['createdAt'];

                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PostDetailScreen(
                                postId: docs[i].id,
                                text: text is String ? text : '',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text is String ? text : '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  StreamBuilder<bool>(
                                    stream: (uid == null || uid.isEmpty)
                                        ? Stream<bool>.value(false)
                                        : _postRepository.streamLikeStatus(
                                            uid: uid,
                                            postId: docs[i].id,
                                          ),
                                    builder: (context, likeSnapshot) {
                                      final liked = likeSnapshot.data ?? false;
                                      return IconButton(
                                        icon: Icon(
                                          liked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                        ),
                                        onPressed: (uid == null || uid.isEmpty)
                                            ? null
                                            : () async {
                                                await _postRepository
                                                    .toggleLike(
                                                  uid: uid,
                                                  postId: docs[i].id,
                                                );
                                              },
                                      );
                                    },
                                  ),
                                  Text(
                                    '${likeCount is num ? likeCount : 0}',
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Comments ${commentCount is num ? commentCount : 0}',
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatCreatedAt(createdAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
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
          onPressed: () => _openCreatePost(context),
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}
