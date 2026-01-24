import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus {
  searching,
  pending,
  accepted,
  rejected,
  skipped,
  expired,
}

class MatchSession {
  final String id;
  final String userA;
  final String userB;
  final MatchStatus status;
  final String? chatRoomId;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final String? mode;
  final Map<String, String?> responses;

  MatchSession({
    required this.id,
    required this.userA,
    required this.userB,
    required this.status,
    required this.chatRoomId,
    required this.createdAt,
    required this.respondedAt,
    this.expiresAt,
    this.mode,
    required this.responses,
  });

  factory MatchSession.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MatchSession(
      id: doc.id,
      userA: (data['userA'] ?? '').toString(),
      userB: (data['userB'] ?? '').toString(),
      status: _statusFromString(data['status']),
      chatRoomId: data['chatRoomId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      mode: data['mode'] as String?,
      responses: _responsesFromMap(data['responses']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userA': userA,
      'userB': userB,
      'status': _statusToString(status),
      'chatRoomId': chatRoomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt == null ? null : Timestamp.fromDate(respondedAt!),
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'mode': mode,
      'responses': responses,
    };
  }

  static MatchStatus _statusFromString(Object? value) {
    switch (value?.toString()) {
      case 'searching':
        return MatchStatus.searching;
      case 'pending':
        return MatchStatus.pending;
      case 'accepted':
        return MatchStatus.accepted;
      case 'rejected':
        return MatchStatus.rejected;
      case 'skipped':
        return MatchStatus.skipped;
      case 'expired':
        return MatchStatus.expired;
    }
    return MatchStatus.pending;
  }

  static String _statusToString(MatchStatus status) {
    switch (status) {
      case MatchStatus.searching:
        return 'searching';
      case MatchStatus.pending:
        return 'pending';
      case MatchStatus.accepted:
        return 'accepted';
      case MatchStatus.rejected:
        return 'rejected';
      case MatchStatus.skipped:
        return 'skipped';
      case MatchStatus.expired:
        return 'expired';
    }
  }

  static Map<String, String?> _responsesFromMap(Object? value) {
    if (value is Map) {
      final result = <String, String?>{};
      for (final entry in value.entries) {
        final key = entry.key?.toString();
        if (key == null || key.isEmpty) continue;
        final response = entry.value?.toString();
        result[key] = response;
      }
      return result;
    }
    return <String, String?>{};
  }
}
