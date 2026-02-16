import 'package:flutter/material.dart';

import 'comment_screen.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.text,
  });

  final String postId;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CommentScreen(postId: postId),
                  ),
                );
              },
              icon: const Icon(Icons.comment_outlined),
              label: const Text('Comments'),
            ),
          ],
        ),
      ),
    );
  }
}
