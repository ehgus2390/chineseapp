import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CommunityProfileRepository {
  CommunityProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> getProfileData(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return null;

    final ref = _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
        .collection('profiles')
        .doc(normalizedUid);

    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) return null;
      return snapshot.data();
    } catch (e, st) {
      debugPrint('CommunityProfileRepository.getProfileData error: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<bool> isProfileComplete(String uid) async {
    final data = await getProfileData(uid);
    if (data == null) return false;

    final nickname = data['nickname'];
    final nationality = data['nationality'];
    final languages = data['languages'];

    final hasNickname = nickname is String && nickname.trim().isNotEmpty;
    final hasNationality =
        nationality is String && nationality.trim().isNotEmpty;
    final hasLanguages = languages is List && languages.isNotEmpty;

    return hasNickname && hasNationality && hasLanguages;
  }

  Future<void> updateSetupFields({
    required String uid,
    required String nickname,
    required String nationality,
    required List<String> languages,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;

    final ref = _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
        .collection('profiles')
        .doc(normalizedUid);

    try {
      await ref.set({
        'nickname': nickname,
        'nationality': nationality,
        'languages': languages,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('CommunityProfileRepository.updateSetupFields error: $e');
      debugPrint('$st');
    }
  }

  Future<void> ensureCommunityProfileExists(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;

    final ref = _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
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
