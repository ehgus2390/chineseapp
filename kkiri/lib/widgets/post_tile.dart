import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
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
      await context.read<AuthProvider>().signInAnonymously();
      return;
    }
    await context.read<PostService>().toggleLike(postId, user.uid);
  }

  Future<void> _addComment(BuildContext context) async {
    final user = context.read<AppState>().user;
    if (user == null) {
      await context.read<AuthProvider>().signInAnonymously();
      return;
    }

    final controller = TextEditingController();
    final text = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 작성'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '댓글을 입력하세요'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      await context.read<PostService>().addComment(postId, user.uid, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = data['content'] as String? ?? '';
    final likesCount = data['likesCount'] ?? 0;
    final currentUser = context.watch<AppState>().user;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            Row(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: currentUser == null
                      ? const Stream.empty()
                      : FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('likes')
                      .doc(currentUser.uid)
                      .snapshots(),
                  builder: (_, snap) {
                    final liked = snap.data?.exists ?? false;
                    return TextButton.icon(
                      onPressed: () => _toggleLike(context),
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.red : null,
                      ),
                      label: Text('Like ($likesCount)'),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () => _addComment(context),
                  icon: const Icon(Icons.comment),
                  label: const Text('Comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
