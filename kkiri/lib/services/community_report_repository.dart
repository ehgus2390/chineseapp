import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityReportRepository {
  CommunityReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> reportPost({
    required String reporterUid,
    required String postId,
    required String reason,
  }) async {
    final uid = reporterUid.trim();
    final pid = postId.trim();
    final value = reason.trim();
    if (uid.isEmpty || pid.isEmpty || value.isEmpty) return;

    final postRef = _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
        .collection('posts')
        .doc(pid);
    final reportRef = postRef.collection('reports').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final reportSnapshot = await transaction.get(reportRef);
      if (reportSnapshot.exists) return;

      final data = postSnapshot.data();
      final rawAuthorUid = data?['authorUid'];
      final authorUid = rawAuthorUid is String ? rawAuthorUid.trim() : '';
      final rawReportCount = data?['reportCount'];
      final currentReportCount = rawReportCount is int
          ? rawReportCount
          : rawReportCount is num
              ? rawReportCount.toInt()
              : 0;
      final nextReportCount = currentReportCount + 1;

      transaction.set(reportRef, {
        'reporterUid': uid,
        'reason': value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final update = <String, dynamic>{
        'reportCount': FieldValue.increment(1),
      };
      if (nextReportCount >= 3) {
        update['isHidden'] = true;
      }

      transaction.update(postRef, update);

      if (authorUid.isEmpty) return;

      final moderationRef =
          _firestore.collection('user_moderation').doc(authorUid);
      final moderationSnapshot = await transaction.get(moderationRef);

      if (!moderationSnapshot.exists) {
        transaction.set(moderationRef, {
          'totalReports': 1,
          'level': 0,
          'reasonCounts': {value: 1},
        });
        return;
      }

      final moderationData = moderationSnapshot.data();
      final rawTotalReports = moderationData?['totalReports'];
      final currentTotalReports = rawTotalReports is int
          ? rawTotalReports
          : rawTotalReports is num
              ? rawTotalReports.toInt()
              : 0;
      final nextTotalReports = currentTotalReports + 1;

      int level = 0;
      if (nextTotalReports >= 6) {
        level = 2;
      } else if (nextTotalReports >= 3) {
        level = 1;
      }

      transaction.update(moderationRef, {
        'totalReports': FieldValue.increment(1),
        'level': level,
        'reasonCounts.$value': FieldValue.increment(1),
      });
    });
  }

  Future<void> reportComment({
    required String reporterUid,
    required String postId,
    required String commentId,
    required String reason,
  }) async {
    final uid = reporterUid.trim();
    final pid = postId.trim();
    final cid = commentId.trim();
    final value = reason.trim();
    if (uid.isEmpty || pid.isEmpty || cid.isEmpty || value.isEmpty) return;

    final ref = _firestore
        .collection('community')
        .doc('apps')
        .collection('main')
        .doc('root')
        .collection('posts')
        .doc(pid)
        .collection('comments')
        .doc(cid)
        .collection('reports')
        .doc(uid);

    await ref.set({
      'reporterUid': uid,
      'reason': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
