import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────── 상태 ─────────
  String? _currentRoomId;
  bool _isJoining = false;
  double _vicinityKm = 5;

  static const int _maxMembers = 20;

  // ───────── getter ─────────
  String? get currentRoomId => _currentRoomId;
  bool get isInRoom => _currentRoomId != null;
  bool get isJoining => _isJoining;
  double get vicinityKm => _vicinityKm;

  // ───────── 설정 ─────────
  void updateVicinity(double value) {
    _vicinityKm = double.parse(value.toStringAsFixed(1));
    notifyListeners();
  }

  // ─────────────────────────
  // 🚪 오픈챗 입장
  // ─────────────────────────
  Future<void> joinRandomRoom(String uid) async {
    if (_isJoining) return;

    _isJoining = true;
    notifyListeners();

    try {
      final roomId =
          await _attachToExistingRoom(uid) ?? await _createRoom(uid);
      _currentRoomId = roomId;
    } finally {
      _isJoining = false;
      notifyListeners();
    }
  }

  // 기존 방 탐색
  Future<String?> _attachToExistingRoom(String uid) async {
    final snap = await _db
        .collection('openChatRooms')
        .where('vicinityKm', isEqualTo: _vicinityKm)
        .where('isOpen', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(10)
        .get();

    final docs = snap.docs.toList()..shuffle(Random());

    for (final doc in docs) {
      final joined = await _tryJoinRoom(doc, uid);
      if (joined != null) return joined;
    }
    return null;
  }

  // 방 참여 시도 (트랜잭션)
  Future<String?> _tryJoinRoom(
      DocumentSnapshot<Map<String, dynamic>> doc,
      String uid,
      ) async {
    return _db.runTransaction<String?>((txn) async {
      final fresh = await txn.get(doc.reference);
      if (!fresh.exists) return null;

      final data = fresh.data();
      if (data == null) return null;
      final members =
      Map<String, dynamic>.from(data['members'] ?? <String, dynamic>{});
      final memberCount =
          (data['memberCount'] as int?) ?? members.length;
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

  // 새 방 생성
  Future<String> _createRoom(String uid) async {
    final ref = await _db.collection('openChatRooms').add({
      'vicinityKm': _vicinityKm,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isOpen': true,
      'memberCount': 1,
      'members': {uid: true},
      'lastMessage': '',
    });
    return ref.id;
  }

  // ─────────────────────────
  // 🚪 오픈챗 퇴장
  // ─────────────────────────
  Future<void> leaveRoom(String uid) async {
    final roomId = _currentRoomId;
    if (roomId == null) return;

    final ref = _db.collection('openChatRooms').doc(roomId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final data = snap.data();
      if (data == null) return;
      final members =
      Map<String, dynamic>.from(data['members'] ?? {});
      if (!members.containsKey(uid)) return;

      members.remove(uid);
      final currentCount = (data['memberCount'] as int?) ?? 1;
      final updatedCount = currentCount - 1;

      txn.update(ref, {
        'members': members,
        'memberCount': updatedCount < 0 ? 0 : updatedCount,
        'isOpen': updatedCount > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    _currentRoomId = null;
    notifyListeners();
  }

  // ─────────────────────────
  // 💬 메시지
  // ─────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> currentRoomMessages() {
    final roomId = _currentRoomId;
    if (roomId == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _db
        .collection('openChatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> sendRoomMessage({
    required String uid,
    required String text,
    required String displayName,
    required bool profileAllowed,
  }) async {
    final roomId = _currentRoomId;
    final value = text.trim();
    if (roomId == null || value.isEmpty) return;

    final roomRef = _db.collection('openChatRooms').doc(roomId);

    await roomRef.collection('messages').add({
      'userId': uid,
      'text': value,
      'displayName': displayName,
      'profileAllowed': profileAllowed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await roomRef.set(
      {
        'lastMessage': value,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ─────────────────────────
  // 📡 현재 방 상태
  // ─────────────────────────
  Stream<DocumentSnapshot<Map<String, dynamic>>> currentRoomSnapshot() {
    final roomId = _currentRoomId;
    if (roomId == null) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _db.collection('openChatRooms').doc(roomId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myChatRooms(String? uid) {
    if (uid == null || uid.isEmpty) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _db
        .collection('chatRooms')
        .where('members', arrayContains: uid)
        .snapshots();
  }
}
