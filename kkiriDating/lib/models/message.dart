import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromDoc(String matchId, DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Message(
      id: doc.id,
      matchId: matchId,
      senderId: (data['senderId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
