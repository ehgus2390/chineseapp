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

  Future<bool> _isBlocked(BuildContext context, String targetUid) async {
    final uid = context.read<AppState>().user?.uid;
    if (uid == null) return false;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blocked')
        .doc(targetUid)
        .get();

    return snap.exists;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user;
    if (currentUser == null) return const SizedBox.shrink();

    final authorId = data['authorId'];

    return FutureBuilder<bool>(
      future: _isBlocked(context, authorId),
      builder: (_, snap) {
        if (snap.data == true) return const SizedBox.shrink();

        final content = data['content'] ?? '';
        final likesCount = data['likesCount'] ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 익명 + ⋮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('익명',
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'report') {
                          await FirebaseFirestore.instance
                              .collection('reports')
                              .add({
                            'type': 'post',
                            'reporterUid': currentUser.uid,
                            'targetUid': authorId,
                            'postId': postId,
                            'createdAt':
                            FieldValue.serverTimestamp(),
                          });
                        } else {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .collection('blocked')
                              .doc(authorId)
                              .set({
                            'createdAt':
                            FieldValue.serverTimestamp(),
                          });
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'report', child: Text('신고')),
                        PopupMenuItem(
                            value: 'block', child: Text('차단')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('좋아요 $likesCount'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
