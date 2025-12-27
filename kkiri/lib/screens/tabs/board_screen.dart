import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/auth_guard.dart';
import '../../services/post_service.dart';
import '../../widgets/post_tile.dart';
import '../../providers/auth_provider.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  Future<void> _openWritePostDialog(BuildContext context) async {
    final controller = TextEditingController();
    final postService = context.read<PostService>();
    final auth = context.read<AuthProvider>();
    final t = AppLocalizations.of(context)!;

    if (!await requireEmailLogin(context, t.post)) return;
    final user = auth.currentUser;
    if (user == null) return;

    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('글쓰기'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(hintText: '내용을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      await postService.createPost(
        uid: user.uid,
        content: text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postService = context.read<PostService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: postService.listenHotPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('게시글이 없습니다.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs
                .map((d) => PostTile(
                      postId: d.id,
                      data: d.data(),
                      showComments: true,
                    ))
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () => _openWritePostDialog(context),
      ),
    );
  }
}
