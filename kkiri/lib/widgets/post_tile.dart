import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/post_service.dart';
import '../state/app_state.dart';

class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.postId,
    required this.data,
    this.showComments = false,
  });

  final String postId;
  final Map<String, dynamic> data;
  final bool showComments;

  Future<void> _toggleLike(BuildContext context) async {
    final user = context.read<AppState>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts.')),
      );
      return;
    }

    await context.read<PostService>().toggleLike(postId, user.uid);
  }

  Future<void> _addComment(BuildContext context) async {
    final user = context.read<AppState>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
      return;
    }

    final controller = TextEditingController();
    final text = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add comment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Write your comment'),
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

    if (text != null && text.isNotEmpty) {
      await context.read<PostService>().addComment(postId, user.uid, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = data['content'] as String? ?? '';
    final likesCount = (data['likesCount'] as int?) ?? 0;
    final appState = context.watch<AppState>();
    final currentUser = appState.user;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: currentUser == null
                      ? null
                      : FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('likes')
                      .doc(currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data?.exists ?? false;
                    return TextButton.icon(
                      onPressed: () => _toggleLike(context),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      label: Text('Like ($likesCount)'),
                    );
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _addComment(context),
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: const Text('Comment'),
                ),
              ],
            ),
            if (showComments) ...[
              const SizedBox(height: 8),
              _CommentsList(postId: postId),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final postService = context.read<PostService>();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: postService.listenComments(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data?.docs ?? [];
        if (comments.isEmpty) {
          return const Text('No comments yet.');
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index].data();
              final text = comment['text'] as String? ?? '';
              final author = comment['authorId'] as String? ?? 'Unknown';
              return ListTile(
                dense: true,
                title: Text(text),
                subtitle: Text('by $author'),
              );
            },
          ),
        );
      },
    );
  }
}
