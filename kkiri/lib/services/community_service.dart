import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> resolveUniversityCommunityId(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data();
    if (data == null) return null;

    final rawId = data['universityCommunityId'] ??
        data['university'] ??
        data['campus'] ??
        data['school'];
    if (rawId is String && rawId.trim().isNotEmpty) {
      return rawId.trim();
    }
    return null;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> listenCommunity(
      String communityId) {
    return _db.collection('communities').doc(communityId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenCommunityPosts(
      String communityId) {
    return _db
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
