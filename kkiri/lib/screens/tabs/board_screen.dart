import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProv = context.watch<PostProvider>();
    final uid = context.read<AuthProvider>().currentUser!.uid;
    final writeCtrl = TextEditingController();

    Widget buildList(Stream<QuerySnapshot<Map<String, dynamic>>> stream, {bool popular = false}) {
      return StreamBuilder(
        stream: stream,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Center(child: Text(popular ? '인기글이 없습니다.' : '게시글이 없습니다.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final id = docs[i].id;
              final d = docs[i].data();
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(d['content'] ?? ''),
                  subtitle: Text('❤ ${d['likesCount'] ?? 0}'),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _PostDetail(postId: id),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_outline),
                    onPressed: () => postProv.toggleLike(id, uid),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: TabBar(
        controller: _tab,
        tabs: const [Tab(text: '전체'), Tab(text: '인기')],
        labelColor: Colors.black,
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          buildList(postProv.postsStream()),
          buildList(postProv.popularPostsStream(minLikes: 5), popular: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('게시글 작성'),
              content: TextField(controller: writeCtrl, maxLines: 5, decoration: const InputDecoration(hintText: '내용 입력')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                ElevatedButton(
                  onPressed: () async {
                    final text = writeCtrl.text.trim();
                    if (text.isEmpty) return;
                    await postProv.writePost(uid, text);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('등록'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PostDetail extends StatelessWidget {
  final String postId;
  const _PostDetail({required this.postId});

  @override
  Widget build(BuildContext context) {
    final postProv = context.read<PostProvider>();
    final auth = context.read<AuthProvider>();
    final commentCtrl = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text('댓글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder(
                stream: postProv.commentsStream(postId),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(d['text'] ?? ''),
                        subtitle: Text(d['authorId'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: commentCtrl, decoration: const InputDecoration(hintText: '댓글 입력'))),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final t = commentCtrl.text.trim();
                    if (t.isEmpty) return;
                    await postProv.addComment(postId, auth.currentUser!.uid, t);
                    commentCtrl.clear();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
