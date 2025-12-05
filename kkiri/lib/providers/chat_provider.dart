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

  /// 대화방 ID 생성 또는 가져오기
  Future<String> createOrGetChatId(String userA, String userB) async {
    final roomId = _chatRoomId(userA, userB);
    final roomRef = _firestore.collection('chats').doc(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      await roomRef.set({
        'users': [userA, userB],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return roomId;
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

  /// 사용자가 참여한 채팅방 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> myChatRooms(String uid) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
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
