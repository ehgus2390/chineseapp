import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsLogger {
  AnalyticsLogger(this._db);

  final FirebaseFirestore _db;

  Future<void> logEvent({
    required String type,
    required String notificationType,
    required String userId,
    String? targetRoute,
  }) async {
    try {
      await _db.collection('analytics_events').add(<String, dynamic>{
        'type': type,
        'notificationType': notificationType,
        'userId': userId,
        if (targetRoute != null) 'targetRoute': targetRoute,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort analytics: never block UX.
    }
  }
}
