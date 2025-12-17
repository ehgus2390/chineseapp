import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/post_service.dart';
import '../../widgets/post_tile.dart';
import '../../providers/auth_provider.dart';
import '../../state/app_state.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthProvider>();
    final postService = context.read<PostService>();

    final uid = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<AppState>().toggleFeedLanguageFilter();
            },
            icon: Icon(
              appState.showOnlyMyLanguages
                  ? Icons.record_voice_over
                  : Icons.public,
              color: Colors.white,
            ),
            label: Text(
              appState.showOnlyMyLanguages ? '내 언어' : '전체',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: postService.listenLatestPosts(),
        builder: (context, postSnap) {
          if (!postSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = postSnap.data!.docs;

          if (uid == null) {
            // 로그인 전 → 전체 게시글 표시
            return _buildPostList(posts);
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = userSnap.data!.data() ?? {};
              final myLanguages =
              List<String>.from(userData['languages'] ?? []);

              final filtered = appState.showOnlyMyLanguages
                  ? posts.where((doc) {
                final lang = doc.data()['language'];
                return lang is String && myLanguages.contains(lang);
              }).toList()
                  : posts;

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('표시할 게시글이 없습니다.'),
                );
              }

              return _buildPostList(filtered);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          final user = auth.currentUser ??
              await auth.signInAnonymouslyUser();
          if (user == null) return;

          // ✍️ 글쓰기 다이얼로그는 다음 단계
        },
      ),
    );
  }

  Widget _buildPostList(List<QueryDocumentSnapshot<Map<String, dynamic>>> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final doc = posts[i];
        return PostTile(
          postId: doc.id,
          data: doc.data(),
          showComments: true,
        );
      },
    );
  }
}
