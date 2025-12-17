import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> listenHotPosts() {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );

    return _db
        .collection('posts')
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt', descending: true)
        .orderBy('likesCount', descending: true)
        .limit(10)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenLatestPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenComments(
      String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createPost({
    required String uid,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;

    String language = 'en';

    final snap = await _db.collection('users').doc(uid).get();
    final mainLang = snap.data()?['mainLanguage'];
    if (mainLang is String && mainLang.isNotEmpty) {
      language = mainLang;
    }

    await _db.collection('posts').add({
      'authorId': uid,
      'content': text,
      'language': language,
      'likesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike(String postId, String uid) async {
    final ref = _db.collection('posts').doc(postId);
    final likeRef = ref.collection('likes').doc(uid);

    await _db.runTransaction((txn) async {
      final liked = await txn.get(likeRef);
      final post = await txn.get(ref);
      final count = (post['likesCount'] ?? 0) as int;

      if (liked.exists) {
        txn.delete(likeRef);
        txn.update(ref, {'likesCount': count - 1});
      } else {
        txn.set(likeRef,
            {'createdAt': FieldValue.serverTimestamp()});
        txn.update(ref, {'likesCount': count + 1});
      }
    });
  }

  Future<void> addComment(
      String postId, String uid, String text) async {
    final value = text.trim();
    if (value.isEmpty) return;

    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'authorId': uid,
      'text': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
