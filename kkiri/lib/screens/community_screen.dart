import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/post.dart';
import '../state/app_state.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = <String, TextEditingController>{};
  final Set<String> _expanded = <String>{};

  @override
  void dispose() {
    _postController.dispose();
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _commentControllerFor(String postId) {
    return _commentControllers.putIfAbsent(postId, () => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l = AppLocalizations.of(context);
    final posts = state.posts;
    final popular = state.popularPosts;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PostComposer(
          controller: _postController,
          onSubmit: (String text) {
            state.addPost(text);
            _postController.clear();
          },
        ),
        const SizedBox(height: 20),
        Text(l.popularPosts, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (popular.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(l.writePost),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int index) {
                final Post post = popular[index];
                final author = state.getById(post.authorId);
                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 16, backgroundImage: NetworkImage(author.avatarUrl)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              author.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          post.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        Text(l.allPosts, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...posts.map((Post post) {
          final author = state.getById(post.authorId);
          final controller = _commentControllerFor(post.id);
          final bool expanded = _expanded.contains(post.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(author.avatarUrl)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(author.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(state.formatTime(post.createdAt)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.content, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.likedBy.contains(state.me.id) ? Icons.favorite : Icons.favorite_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => state.togglePostLike(post.id),
                      ),
                      Text('${post.likedBy.length} ${l.like}'),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (expanded) {
                              _expanded.remove(post.id);
                            } else {
                              _expanded.add(post.id);
                            }
                          });
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text('${post.comments.length} ${l.comment}'),
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const Divider(),
                    if (post.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l.noComments),
                      )
                    else
                      ...post.comments.map((comment) {
                        final commenter = state.getById(comment.authorId);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(radius: 16, backgroundImage: NetworkImage(commenter.avatarUrl)),
                          title: Text(commenter.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(comment.text),
                        );
                      }),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(hintText: l.addComment),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            state.addComment(post.id, controller.text);
                            controller.clear();
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PostComposer extends StatelessWidget {
  const _PostComposer({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.writePost, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l.postPlaceholder,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => onSubmit(controller.text),
              child: Text(l.postButton),
            ),
          ),
        ],
      ),
    );
  }
}
