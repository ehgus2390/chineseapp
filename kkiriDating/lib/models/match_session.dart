import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus {
  searching,
  consent,
  waiting,
  connected,
  cancelled,
}

class MatchSession {
  final String id;
  final List<String> participants;
  final MatchStatus status;
  final Map<String, bool> ready;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? connectedAt;
  final String? cancelledBy;
  final DateTime? expiresAt;

  MatchSession({
    required this.id,
    required this.participants,
    required this.status,
    required this.ready,
    required this.createdAt,
    required this.updatedAt,
    this.connectedAt,
    this.cancelledBy,
    this.expiresAt,
  });

  factory MatchSession.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MatchSession(
      id: doc.id,
      participants: (data['participants'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      status: _statusFromString(data['status']),
      ready: _readyFromMap(data['ready']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      connectedAt: (data['connectedAt'] as Timestamp?)?.toDate(),
      cancelledBy: data['cancelledBy'] as String?,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'participants': participants,
      'status': _statusToString(status),
      'ready': ready,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'connectedAt': connectedAt == null ? null : Timestamp.fromDate(connectedAt!),
      'cancelledBy': cancelledBy,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  static MatchStatus _statusFromString(Object? value) {
    switch (value?.toString()) {
      case 'searching':
        return MatchStatus.searching;
      case 'consent':
        return MatchStatus.consent;
      case 'waiting':
        return MatchStatus.waiting;
      case 'connected':
        return MatchStatus.connected;
      case 'cancelled':
        return MatchStatus.cancelled;
    }
    return MatchStatus.searching;
  }

  static String _statusToString(MatchStatus status) {
    switch (status) {
      case MatchStatus.searching:
        return 'searching';
      case MatchStatus.consent:
        return 'consent';
      case MatchStatus.waiting:
        return 'waiting';
      case MatchStatus.connected:
        return 'connected';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }

  static Map<String, bool> _readyFromMap(Object? value) {
    final Map<String, bool> result = <String, bool>{};
    final Map<String, dynamic>? map = value as Map<String, dynamic>?;
    if (map == null) return result;
    for (final entry in map.entries) {
      result[entry.key] = entry.value == true;
    }
    return result;
  }
}
