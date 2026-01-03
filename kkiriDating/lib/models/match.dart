import 'package:cloud_firestore/cloud_firestore.dart';

class MatchPair {
  final String id;
  final List<String> userIds;
  final DateTime? createdAt;
  final String lastMessage;
  final DateTime? lastMessageAt;

  MatchPair({
    required this.id,
    required this.userIds,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory MatchPair.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MatchPair(
      id: doc.id,
      userIds: (data['userIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}
