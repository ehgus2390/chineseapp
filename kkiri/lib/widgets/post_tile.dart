import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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

  /// 🔐 익명 포함 사용자 보장
  Future<fb.User?> _ensureUser(BuildContext context) async {
    final appState = context.read<AppState>();
    if (appState.user != null) return appState.user;

    await context.read<AuthProvider>().signInAnonymously();
    return context.read<AppState>().user;
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AppState>().user?.uid;
    final authorId = data['authorId'] as String?;

    // 로그인 안 된 상태 → 차단 체크 생략
    if (myUid == null || authorId == null) {
      return _buildCard(context);
    }

    // 🚫 차단 유저 게시글 필터
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('blocked')
          .doc(authorId)
          .get(),
      builder: (context, snap) {
        if (snap.data?.exists == true) {
          return const SizedBox.shrink();
        }
        return _buildCard(context);
      },
    );
  }

  /// 🧱 게시글 UI
  Widget _buildCard(BuildContext context) {
    final content = data['content'] as String? ?? '';
    final likesCount = (data['likesCount'] as int?) ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 익명 표시
            const Text(
              '익명',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),

            // 📝 본문
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 8),

            // ❤️ 좋아요 / 💬 댓글
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.favorite_border),
                  label: Text('좋아요 ($likesCount)'),
                  onPressed: () async {
                    final user = await _ensureUser(context);
                    if (user == null) return;

                    await context
                        .read<PostService>()
                        .toggleLike(postId, user.uid);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: const Text('댓글'),
                  onPressed: () async {
                    final user = await _ensureUser(context);
                    if (user == null) return;

                    _openCommentDialog(context, user.uid);
                  },
                ),
              ],
            ),

            if (showComments) _CommentsList(postId: postId),
          ],
        ),
      ),
    );
  }

  /// 💬 댓글 작성
  void _openCommentDialog(BuildContext context, String uid) async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('댓글 작성'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '댓글을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      await context
          .read<PostService>()
          .addComment(postId, uid, text);
    }
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    final postService = context.read<PostService>();
    final myUid = context.read<AppState>().user?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: postService.listenComments(postId),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final comments = snap.data!.docs;

        // 🚫 차단 유저 댓글 필터
        final filtered = comments.where((doc) {
          final authorId = doc.data()['authorId'];
          return authorId != myUid;
        }).toList();

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '댓글이 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: filtered.map((doc) {
            return ListTile(
              dense: true,
              title: Text(doc.data()['text'] ?? ''),
              subtitle: const Text(
                '익명',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
