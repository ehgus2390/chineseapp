import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🟢 새 게시글 추가
  Future<void> createPost(String authorId, String content) async {
    await _db.collection('posts').add({
      'authorId': authorId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
    });
  }

  // 🟢 게시글 수정
  Future<void> updatePost(String postId, String newContent) async {
    await _db.collection('posts').doc(postId).update({
      'content': newContent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🟢 게시글 삭제
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // 🟢 게시글 전체 조회
  Stream<QuerySnapshot> getAllPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots();
  }

  // 🟢 댓글 추가
  Future<void> addComment(String postId, String authorId, String text) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'authorId': authorId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🟢 댓글 조회
  Stream<QuerySnapshot> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🟢 좋아요 기능
  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    final postRef = _db.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _db.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      final currentLikes = (postSnapshot['likesCount'] ?? 0) as int;

      if (isLiked) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likesCount': currentLikes - 1});
      } else {
        transaction.set(likeRef, {'liked': true});
        transaction.update(postRef, {'likesCount': currentLikes + 1});
      }
    });
  }
}
