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
}
