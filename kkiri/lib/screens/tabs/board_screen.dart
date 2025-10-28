import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _controller = TextEditingController();

  Future<void> _addPost(String uid, String text) async {
    if (text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': uid,
      'text': text.trim(),
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  Future<void> _likePost(String id) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(id);
    await FirebaseFirestore.instance.runTransaction((t) async {
      final snap = await t.get(ref);
      final current = (snap['likes'] ?? 0) as int;
      t.update(ref, {'likes': current + 1});
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티 게시판')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '게시글을 입력하세요...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _addPost(uid, _controller.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final p = posts[i];
                    final data = p.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text(data['text'] ?? ''),
                        subtitle: Text(
                          data['createdAt'] != null
                              ? (data['createdAt'] as Timestamp).toDate().toString()
                              : '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${data['likes'] ?? 0}'),
                            IconButton(
                              icon: const Icon(Icons.thumb_up_alt_outlined),
                              onPressed: () => _likePost(p.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
