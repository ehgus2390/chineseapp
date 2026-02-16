import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostRepository {
  CommunityPostRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts => _firestore
      .collection('community')
      .doc('apps')
      .collection('main')
      .doc('root')
      .collection('posts');

  DocumentReference<Map<String, dynamic>> _postRef(String postId) =>
      _posts.doc(postId);

  Future<void> createPost({
    required String uid,
    required String text,
    required String type,
    String school = '',
    String region = '',
    bool isAnonymous = true,
  }) async {
    final authorUid = uid.trim();
    final value = text.trim();
    final postType = type.trim();
    if (authorUid.isEmpty || value.isEmpty || postType.isEmpty) return;

    await _posts.add({
      'authorUid': authorUid,
      'text': value,
      'type': postType,
      'school': school.trim(),
      'region': region.trim(),
      'likeCount': 0,
      'commentCount': 0,
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike({
    required String uid,
    required String postId,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedPostId = postId.trim();
    if (normalizedUid.isEmpty || normalizedPostId.isEmpty) return;

    final postRef = _postRef(normalizedPostId);
    final likeRef = postRef.collection('likes').doc(normalizedUid);

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(likeRef, {
          'likedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likeCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<bool> streamLikeStatus({
    required String uid,
    required String postId,
  }) {
    final normalizedUid = uid.trim();
    final normalizedPostId = postId.trim();
    if (normalizedUid.isEmpty || normalizedPostId.isEmpty) {
      return Stream<bool>.value(false);
    }

    return _postRef(normalizedPostId)
        .collection('likes')
        .doc(normalizedUid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
