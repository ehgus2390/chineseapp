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
  bool get hasUniversityCommunity =>
      _universityCommunityId != null && _universityCommunityId!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForUser(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _universityCommunityId =
          await _service.resolveUniversityCommunityId(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> universityCommunityStream() {
    final id = _universityCommunityId;
    if (id == null || id.isEmpty) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _service.listenCommunity(id);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> universityPostsStream() {
    final id = _universityCommunityId;
    if (id == null || id.isEmpty) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _service.listenCommunityPosts(id);
  }
}
