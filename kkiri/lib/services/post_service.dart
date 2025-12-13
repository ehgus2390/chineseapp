import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final _db = FirebaseFirestore.instance;

  // ✅ 기존 코드 호환용 (CommunityPage가 listenPosts를 부름)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenPosts() => listenLatestPosts();

  // ✅ HomePage 호환용 (listenPopularPosts 누락 에러 해결)
  Stream<QuerySnapshot<Map<String, dynamic>>> listenPopularPosts() => listenHotPosts();

  Stream<QuerySnapshot<Map<String, dynamic>>> listenLatestPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenHotPosts() {
    final since = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));

    // createdAt + likesCount 복합 정렬이면 인덱스 필요할 수 있음
    return _db
        .collection('posts')
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt', descending: true)
        .orderBy('likesCount', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> createPost(String uid, String content) async {
    await _db.collection('posts').add({
      'authorId': uid,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
    });
  }

  // ✅ 좋아요는 익명도 가능 (uid만 있으면 됨 = 익명 유저 uid OK)
  Future<void> toggleLike(String postId, String uid) async {
    final ref = _db.collection('posts').doc(postId);
    final likeRef = ref.collection('likes').doc(uid);

    await _db.runTransaction((txn) async {
      final likedSnap = await txn.get(likeRef);
      final postSnap = await txn.get(ref);

      final postData = postSnap.data() as Map<String, dynamic>? ?? {};
      final count = (postData['likesCount'] as int?) ?? 0;

      if (likedSnap.exists) {
        txn.delete(likeRef);
        txn.update(ref, {'likesCount': (count - 1) < 0 ? 0 : (count - 1)});
      } else {
        txn.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        txn.update(ref, {'likesCount': count + 1});
      }
    });
  }

  // ✅ 댓글
  Stream<QuerySnapshot<Map<String, dynamic>>> listenComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addComment(String postId, String uid, String text) async {
    final ref = _db.collection('posts').doc(postId).collection('comments');
    await ref.add({
      'authorId': uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
