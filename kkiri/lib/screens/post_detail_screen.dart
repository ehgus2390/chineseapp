import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'comment_screen.dart';
import '../services/community_post_repository.dart';
import '../state/app_state.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.text,
  });

  final String postId;
  final String text;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().user?.uid;
    final postRepository = CommunityPostRepository();
    final postStream = FirebaseFirestore.instance
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
        .collection('posts')
        .doc(postId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: postStream,
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final likeCount = data?['likeCount'];
                final content = data?['text'] ?? text;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content is String ? content : text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StreamBuilder<bool>(
                          stream: (uid == null || uid.isEmpty)
                              ? Stream<bool>.value(false)
                              : postRepository.streamLikeStatus(
                                  uid: uid,
                                  postId: postId,
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
                                      await postRepository.toggleLike(
                                        uid: uid,
                                        postId: postId,
                                      );
                                    },
                            );
                          },
                        ),
                        Text('${likeCount is num ? likeCount : 0}'),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CommentScreen(postId: postId),
                  ),
                );
              },
              icon: const Icon(Icons.comment_outlined),
              label: const Text('Comments'),
            ),
          ],
        ),
      ),
    );
  }
}
