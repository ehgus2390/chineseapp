import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  ChatService(this._db);

  final FirebaseFirestore _db;

  Stream<List<Message>> watchMessages(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromDoc(matchId, doc)).toList());
  }

  Future<void> send(String matchId, String senderId, String text) async {
    final now = FieldValue.serverTimestamp();
    final messages = _db.collection('matches').doc(matchId).collection('messages');
    await messages.add(<String, dynamic>{
      'senderId': senderId,
      'text': text,
      'createdAt': now,
    });
    await _db.collection('matches').doc(matchId).set(<String, dynamic>{
      'lastMessage': text,
      'lastMessageAt': now,
    }, SetOptions(merge: true));
  }
}
