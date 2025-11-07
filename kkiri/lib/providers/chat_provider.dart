import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a unique and predictable chat room id for two users.
  String _chatRoomId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join('_');
  }

  /// Creates the chat room document if it doesn't exist and returns the id.
  Future<String> createOrGetChatId(String userA, String userB) async {
    final roomId = _chatRoomId(userA, userB);
    final roomRef = _firestore.collection('chats').doc(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      await roomRef.set({
        'users': [userA, userB],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });
    }

    return roomId;
  }

  /// Sends a message between [senderId] and [receiverId].
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final roomId = await createOrGetChatId(senderId, receiverId);
    final messageRef = _firestore.collection('chats').doc(roomId).collection('messages');

    await messageRef.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(roomId).set({
      'lastMessage': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
      'users': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  /// Stream of messages for a conversation between [userA] and [userB].
  Stream<QuerySnapshot<Map<String, dynamic>>> messageStream(String userA, String userB) {
    final roomId = _chatRoomId(userA, userB);
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Stream of all chat rooms the user is part of, ordered by the last update time.
  Stream<QuerySnapshot<Map<String, dynamic>>> myChatRooms(String uid) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}