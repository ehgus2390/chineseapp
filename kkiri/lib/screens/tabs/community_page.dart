// lib/screens/tabs/community_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../state/app_state.dart';
import '../../widgets/post_tile.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  Future<void> _showCreatePostDialog(BuildContext context) async {
    final controller = TextEditingController();
    final appState = context.read<AppState>();
    final postService = context.read<PostService>();
    final user = appState.user;

    if (user == null) {
      await context.read<AuthProvider>().signInAnonymously();
      return;
    }

    final content = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create post'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Share something...'),
            maxLines: 4,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Post'),
            ),
          ],
        );
      },
    );

    if (content != null && content.isNotEmpty) {
      await postService.createPost(user.uid, content);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postService = context.read<PostService>();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: postService.listenPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Be the first to share something!'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return PostTile(
                postId: doc.id,
                data: doc.data(),
                showComments: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(context),
        icon: const Icon(Icons.edit),
        label: const Text('Post'),
      ),
    );
  }
}
