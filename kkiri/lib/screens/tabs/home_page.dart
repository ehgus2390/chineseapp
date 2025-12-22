import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/post_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openWritePostDialog(BuildContext context) async {
    final controller = TextEditingController();
    final postService = context.read<PostService>();
    final auth = context.read<AuthProvider>();
    final t = AppLocalizations.of(context);

    final user = auth.currentUser ?? await auth.signInAnonymouslyUser();
    if (user == null) return;

    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.writePostTitle),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(hintText: t.writePostHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(t.submitPost),
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
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final postService = context.read<PostService>();

    final uid = auth.currentUser?.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openWritePostDialog(context),
        child: const Icon(Icons.edit),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _CampusSelector(uid: uid, label: t.homeCampusLabel),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: postService.listenLatestPosts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(child: Text(t.homeFeedEmpty));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return PostTile(
                        postId: doc.id,
                        data: doc.data(),
                        showComments: false,
                      );
                    },
                  );
                },
              ),
            ),
            _CategoryShortcuts(
              categories: [
                _CategoryItem(
                  icon: Icons.restaurant_menu,
                  label: t.categoryFood,
                ),
                _CategoryItem(
                  icon: Icons.school,
                  label: t.categoryClasses,
                ),
                _CategoryItem(
                  icon: Icons.group,
                  label: t.friends,
                ),
                _CategoryItem(
                  icon: Icons.home_work_outlined,
                  label: t.categoryHousing,
                ),
                _CategoryItem(
                  icon: Icons.public,
                  label: t.categoryLifeInKorea,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampusSelector extends StatelessWidget {
  const _CampusSelector({required this.uid, required this.label});

  final String? uid;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: uid == null
          ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
          : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final campusName = (data?['university'] ??
                data?['campus'] ??
                data?['school']) as String? ??
            t.homeCampusFallback;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_city, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  campusName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryShortcuts extends StatelessWidget {
  const _CategoryShortcuts({required this.categories});

  final List<_CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFB),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final item = categories[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: categories.length,
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
