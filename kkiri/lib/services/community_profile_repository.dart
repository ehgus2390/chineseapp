import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CommunityProfileRepository {
  CommunityProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> ensureCommunityProfileExists(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;

    final ref = _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .collection('profiles')
        .doc(normalizedUid);

    try {
      final snapshot = await ref.get();
      if (snapshot.exists) return;

      await ref.set({
        'nickname': null,
        'photoUrl': null,
        'nationality': null,
        'languages': [],
        'school': null,
        'interests': [],
        'location': null,
        'locationEnabled': false,
        'radiusKm': 5,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint(
        'CommunityProfileRepository.ensureCommunityProfileExists error: $e',
      );
      debugPrint('$st');
    }
  }
}
