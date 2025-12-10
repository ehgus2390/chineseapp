import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  static const int _maxMembers = 20;

  double _vicinityKm = 5;
  bool _isJoining = false;
  String? _currentRoomId;

  double get vicinityKm => _vicinityKm;
  bool get isJoining => _isJoining;
  String? get currentRoomId => _currentRoomId;
  bool get isInRoom => _currentRoomId != null;

  void updateVicinity(double value) {
    _vicinityKm = double.parse(value.toStringAsFixed(1));
    notifyListeners();
  }

  /// 대화방 ID 생성 (양쪽 UID를 정렬해서 항상 동일)
  String _chatRoomId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return ids.join('_');
  }

  Future<String> createOrGetChatId(String userA, String userB) async {
    final roomId = _chatRoomId(userA, userB);
    final ref = _firestore.collection('chats').doc(roomId);
    await ref.set({
      'users': [userA, userB],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return roomId;
  }

  /// 1:1 메시지 전송
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
    }, SetOptions(merge: true));
  }

  /// 실시간 메시지 스트림 (1:1)
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

  /// 익명 오픈채팅 방 랜덤 입장
  Future<void> joinRandomRoom(String uid) async {
    _isJoining = true;
    notifyListeners();

    try {
      final roomId = await _attachToExistingRoom(uid) ?? await _createRoom(uid);
      _currentRoomId = roomId;
    } finally {
      _isJoining = false;
      notifyListeners();
    }
  }

  Future<String?> _attachToExistingRoom(String uid) async {
    final snapshot = await _firestore
        .collection('openChatRooms')
        .where('vicinityKm', isEqualTo: _vicinityKm)
        .where('isOpen', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(10)
        .get();

    final docs = snapshot.docs.toList()..shuffle(Random());
    for (final doc in docs) {
      final joinedId = await _tryJoinRoom(doc, uid);
      if (joinedId != null) return joinedId;
    }
    return null;
  }

  Future<String?> _tryJoinRoom(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String uid,
  ) async {
    return _firestore.runTransaction((txn) async {
      final fresh = await txn.get(doc.reference);
      if (!fresh.exists) return null;
      final data = fresh.data() ?? {};
      final members = Map<String, dynamic>.from(data['members'] ?? {});
      final memberCount = (data['memberCount'] as int?) ?? members.length;

      final isOpen = data['isOpen'] as bool? ?? true;
      if (!isOpen || memberCount >= _maxMembers) return null;

      if (members.containsKey(uid)) {
        txn.update(doc.reference, {
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return doc.id;
      }

      members[uid] = true;
      txn.update(doc.reference, {
        'members': members,
        'memberCount': memberCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    }).catchError((_) => null);
  }

  Future<String> _createRoom(String uid) async {
    final ref = await _firestore.collection('openChatRooms').add({
      'vicinityKm': _vicinityKm,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isOpen': true,
      'memberCount': 1,
      'members': {uid: true},
    });
    return ref.id;
  }

  Future<void> leaveRoom(String uid) async {
    final roomId = _currentRoomId;
    if (roomId == null) return;
    final ref = _firestore.collection('openChatRooms').doc(roomId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final members = Map<String, dynamic>.from(data['members'] ?? {});
      if (!members.containsKey(uid)) return;
      members.remove(uid);
      final currentCount = (data['memberCount'] as int?) ?? 1;
      final updatedCount = currentCount - 1;

      txn.update(ref, {
        'members': members,
        'memberCount': updatedCount < 0 ? 0 : updatedCount,
        'updatedAt': FieldValue.serverTimestamp(),
        'isOpen': updatedCount > 0,
      });
    });

    _currentRoomId = null;
    notifyListeners();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> currentRoomSnapshot() {
    final roomId = _currentRoomId;
    if (roomId == null) {
      return const Stream.empty();
    }
    return _firestore.collection('openChatRooms').doc(roomId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> currentRoomMessagesStream() {
    final roomId = _currentRoomId;
    if (roomId == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('openChatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> sendRoomMessage({
    required String userId,
    required String text,
    required String displayName,
    required bool profileAllowed,
  }) async {
    final roomId = _currentRoomId;
    if (roomId == null || text.trim().isEmpty) return;
    final message = {
      'userId': userId,
      'text': text.trim(),
      'displayName': displayName,
      'profileAllowed': profileAllowed,
      'createdAt': FieldValue.serverTimestamp(),
    };
    final roomRef = _firestore.collection('openChatRooms').doc(roomId);
    await roomRef.collection('messages').add(message);
    await roomRef.update({
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
