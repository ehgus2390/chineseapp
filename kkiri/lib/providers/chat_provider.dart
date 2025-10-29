import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  /// 대화방 ID 생성 (양쪽 UID를 정렬해서 항상 동일)
  String _chatRoomId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join('_');
  }

  /// 메시지 전송
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final roomId = _chatRoomId(senderId, receiverId);
    final ref = _firestore.collection('chats').doc(roomId).collection('messages');

    await ref.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 최근 메시지 캐시 (리스트용)
    await _firestore.collection('chats').doc(roomId).set({
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'users': [senderId, receiverId],
    });
  }

  /// 실시간 메시지 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> messageStream(
      String userA, String userB) {
    final roomId = _chatRoomId(userA, userB);
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
