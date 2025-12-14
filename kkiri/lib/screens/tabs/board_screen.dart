// lib/screens/tabs/board_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/post_service.dart';
import '../../widgets/post_tile.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = context.read<PostService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('🔥 인기 게시글', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),

          /// 🔥 HOT POSTS
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: postService.listenHotPosts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Text('인기 게시글이 없습니다.');
              }

              return Column(
                children: docs
                    .map(
                      (d) => PostTile(
                    postId: d.id,
                    data: d.data(),
                  ),
                )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text('🆕 최신 게시글', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),

          /// 🆕 LATEST POSTS
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: postService.listenLatestPosts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Text('게시글이 없습니다.');
              }

              return Column(
                children: docs
                    .map(
                      (d) => PostTile(
                    postId: d.id,
                    data: d.data(),
                    showComments: true,
                  ),
                )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
