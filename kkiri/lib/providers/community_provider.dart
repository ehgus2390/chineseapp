import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  CommunityProvider({CommunityService? service})
      : _service = service ?? CommunityService();

  final CommunityService _service;

  String? _universityCommunityId;
  bool _isLoading = false;
  String? _error;

  String? get universityCommunityId => _universityCommunityId;

  /// 🔑 익명 / 로그인 모두 안전
  bool get hasUniversityCommunity =>
      _universityCommunityId != null && _universityCommunityId!.isNotEmpty;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─────────────────────────────────────────
  // 로그인 유저용 로드
  // ─────────────────────────────────────────
  Future<void> loadForUser(String uid) async {
    _setLoading();

    try {
      final id = await _service.resolveUniversityCommunityId(uid);
      _universityCommunityId = (id != null && id.isNotEmpty) ? id : null;
    } catch (e, s) {
      debugPrint('CommunityProvider.loadForUser error: $e\n$s');
      _error = e.toString();
      _universityCommunityId = null;
    } finally {
      _endLoading();
    }
  }

  // ─────────────────────────────────────────
  // 🔑 익명 유저용 (공개 커뮤니티)
  // ─────────────────────────────────────────
  Future<void> loadPublic() async {
    _setLoading();

    try {
      final id = await _service.resolveDefaultCommunityId();

      // ❗ 핵심: null / empty 완전 차단
      _universityCommunityId = (id != null && id.isNotEmpty) ? id : null;
    } catch (e, s) {
      debugPrint('CommunityProvider.loadPublic error: $e\n$s');
      _error = e.toString();
      _universityCommunityId = null;
    } finally {
      _endLoading();
    }
  }

  // ─────────────────────────────────────────
  // 커뮤니티 메타 정보 스트림
  // ─────────────────────────────────────────
  Stream<DocumentSnapshot<Map<String, dynamic>>> universityCommunityStream() {
    final id = _universityCommunityId;

    if (id == null || id.isEmpty) {
      // ⚠️ 절대 크래시 안 나는 패턴
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    return _service.listenCommunity(id);
  }

  // ─────────────────────────────────────────
  // 커뮤니티 게시글 스트림
  // ─────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> universityPostsStream() {
    final id = _universityCommunityId;

    if (id == null || id.isEmpty) {
      // ⚠️ 익명 사용자 / 데이터 없음 → 그냥 빈 리스트
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _service.listenCommunityPosts(id);
  }

  // ─────────────────────────────────────────
  // 내부 유틸
  // ─────────────────────────────────────────
  void _setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _endLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
