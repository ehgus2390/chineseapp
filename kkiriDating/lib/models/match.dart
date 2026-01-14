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

class MatchSession {
  final String id;
  final List<String> pendingUserIds;
  final Map<String, bool> ready;
  final bool connected;

  MatchSession({
    required this.id,
    required this.pendingUserIds,
    required this.ready,
    required this.connected,
  });

  factory MatchSession.fromMap(String id, Map<String, dynamic> data) {
    final List<String> pendingIds = (data['pendingUserIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final Map<String, dynamic>? readyMap =
        data['ready'] as Map<String, dynamic>?;
    final Map<String, bool> ready = <String, bool>{};
    if (readyMap != null) {
      for (final entry in readyMap.entries) {
        ready[entry.key] = entry.value == true;
      }
    }
    final List<dynamic>? userIds = data['userIds'] as List<dynamic>?;
    final bool connected = userIds != null && userIds.isNotEmpty;
    return MatchSession(
      id: id,
      pendingUserIds: pendingIds,
      ready: ready,
      connected: connected,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pendingUserIds': pendingUserIds,
      'ready': ready,
      'connected': connected,
    };
  }
}
