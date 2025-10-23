import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();
  int tab = 0; // 0: 사용자, 1: 게시글

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '검색어 입력'))),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [tab==0, tab==1],
                  onPressed: (i)=>setState(()=>tab=i),
                  children: const [Padding(padding: EdgeInsets.all(8), child: Text('사용자')), Padding(padding: EdgeInsets.all(8), child: Text('게시글'))],
                ),
              ],
            ),
          ),
          Expanded(
            child: ctrl.text.isEmpty ? const Center(child: Text('검색어를 입력하세요')) :
            StreamBuilder(
              stream: tab==0
                  ? FirebaseFirestore.instance.collection('users')
                  .where('displayName', isGreaterThanOrEqualTo: ctrl.text)
                  .where('displayName', isLessThan: '${ctrl.text}\uf8ff').snapshots()
                  : FirebaseFirestore.instance.collection('posts')
                  .where('content', isGreaterThanOrEqualTo: ctrl.text)
                  .where('content', isLessThan: '${ctrl.text}\uf8ff').snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = (snap.data as QuerySnapshot).docs;
                if (docs.isEmpty) return const Center(child: Text('결과가 없습니다.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text((tab==0 ? (d['displayName'] ?? '') : (d['content'] ?? ''))),
                      subtitle: Text(tab==0 ? '@${d['searchId'] ?? ''}' : '❤ ${d['likesCount'] ?? 0}'),
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
