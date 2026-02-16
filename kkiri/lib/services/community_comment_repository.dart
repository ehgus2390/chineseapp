import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentRepository {
  CommunityCommentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) {
    return _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
        .collection('posts')
        .doc(postId)
        .collection('comments');
  }

  Future<void> createComment({
    required String uid,
    required String postId,
    required String text,
    bool isAnonymous = true,
  }) async {
    final authorUid = uid.trim();
    final normalizedPostId = postId.trim();
    final value = text.trim();
    if (authorUid.isEmpty || normalizedPostId.isEmpty || value.isEmpty) return;

    final postRef = _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
        .collection('posts')
        .doc(normalizedPostId);
    final commentRef = _commentsRef(normalizedPostId).doc();

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      transaction.set(commentRef, {
        'authorUid': authorUid,
        'text': value,
        'isAnonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<QuerySnapshot> streamComments(String postId) {
    final normalizedPostId = postId.trim();
    if (normalizedPostId.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }

    return _commentsRef(
      normalizedPostId,
    ).orderBy('createdAt', descending: false).snapshots();
  }
}
