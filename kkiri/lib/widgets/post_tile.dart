import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/post_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final myLang = context.read<LocaleProvider>().locale?.languageCode;
    final postLang = data['language'] as String?;

    final showTranslate =
        myLang != null && postLang != null && myLang != postLang;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('?�명',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(data['content'] ?? ''),
            if (showTranslate)
              TextButton.icon(
                icon: const Icon(Icons.translate),
                label: const Text('번역'),
                onPressed: () {},
              ),
            TextButton.icon(
              icon: const Icon(Icons.favorite_border),
              label: Text('좋아??${(data['likesCount'] ?? 0)}'),
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final user =
                    auth.currentUser ?? await auth.signInAnonymouslyUser();
                final uid = user?.uid;
                if (uid == null) return;
                await context.read<PostService>().toggleLike(postId, uid);
              },
            ),
          ],
        ),
      ),
    );
  }
}



