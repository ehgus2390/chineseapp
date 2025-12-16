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
    final postService = context.read<PostService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: postService.listenLatestPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('게시글이 없습니다.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];
              return PostTile(
                postId: d.id,
                data: d.data(),
                showComments: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          final user = context.read<AppState>().user ??
              await context.read<AuthProvider>().signInAnonymously();
          if (user == null) return;

          // TODO: 글쓰기 다이얼로그
        },
      ),
    );
  }
}
