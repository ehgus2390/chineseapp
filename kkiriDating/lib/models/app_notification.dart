import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type;
  final String? fromUid;
  final String? refId;
  final bool seen;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.refId,
    required this.seen,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      type: (data['type'] ?? '').toString(),
      fromUid: data['fromUid']?.toString(),
      refId: data['refId']?.toString(),
      seen: data['seen'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
