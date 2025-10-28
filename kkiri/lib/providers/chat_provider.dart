import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  Future<String> createOrGetChatId(String uid1, String uid2) async {
    final ids = [uid1, uid2]..sort();
    final chatId = ids.join('_');
    final ref = _db.collection('chats').doc(chatId);
    if (!(await ref.get()).exists) {
      await ref.set({
        'members': ids,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
      });
    }
    return chatId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myChatRooms(String uid) {
    return _db.collection('chats')
        .where('members', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId) {
    return _db.collection('chats').doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> sendTextMessage(String chatId, String senderId, String text) async {
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
    await msgRef.set({
      'senderId': senderId,
      'text': text,
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('chats').doc(chatId)
        .update({'updatedAt': FieldValue.serverTimestamp(), 'lastMessage': text});
  }

  Future<void> sendImageMessage(String chatId, String senderId, String imageUrl) async {
    final msgRef = _db.collection('chats').doc(chatId).collection('messages').doc();
    await msgRef.set({
      'senderId': senderId,
      'text': null,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('chats').doc(chatId)
        .update({'updatedAt': FieldValue.serverTimestamp(), 'lastMessage': '📷 photo'});
  }
}
