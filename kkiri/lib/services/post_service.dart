import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final _db = FirebaseFirestore.instance;

  /// 🔥 인기 게시글 (24시간 + 좋아요)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenHotPosts() {
    final since =
    Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));

    return _db
        .collection('posts')
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt', descending: true)
        .orderBy('likesCount', descending: true)
        .limit(10)
        .snapshots();
  }

  /// 🆕 최신 게시글
  Stream<QuerySnapshot<Map<String, dynamic>>> listenLatestPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 💬 댓글 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> listenComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✍️ 게시글 작성 (🔥 핵심)
  Future<void> createPost({
    required String uid,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    await _db.collection('posts').add({
      'authorId': uid,
      'content': content.trim(),
      'likesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ❤️ 좋아요 토글
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
        txn.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        txn.update(ref, {'likesCount': count + 1});
      }
    });
  }

  /// 💬 댓글 작성
  Future<void> addComment(String postId, String uid, String text) async {
    if (text.trim().isEmpty) return;

    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'authorId': uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
