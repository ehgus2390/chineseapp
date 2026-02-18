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

  Future<void> _ensurePostingAllowed(String uid) async {
    final moderationRef = _firestore.collection('user_moderation').doc(uid);
    final moderationSnap = await moderationRef.get();
    final data = moderationSnap.data();
    final rawLevel = data?['level'];
    final level = rawLevel is int
        ? rawLevel
        : rawLevel is num
            ? rawLevel.toInt()
            : 0;

    if (level >= 2) {
      throw Exception('Posting restricted due to policy violation.');
    }
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
    await _ensurePostingAllowed(authorUid);

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
        'hotScore': FieldValue.increment(2),
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
