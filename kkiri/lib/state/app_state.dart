// lib/state/app_state.dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/community_profile_repository.dart';

class AppUser {
  const AppUser({required this.uid, required this.isAnonymous});

  final String uid;
  final bool isAnonymous;
}

class AppState extends ChangeNotifier {
  AppState({
    AuthService? authService,
    CommunityProfileRepository? communityProfileRepository,
  })  : _authService = authService ?? AuthService(),
        _communityProfileRepository =
            communityProfileRepository ?? CommunityProfileRepository();

  final AuthService _authService;
  final CommunityProfileRepository _communityProfileRepository;

  AppUser? _user;
  AppUser? get user => _user;

  bool isLoading = false;
  bool isCheckingCommunityProfile = false;
  bool isCommunityProfileComplete = true;

  // 피드 언어 필터링
  bool showOnlyMyLanguages = true;

  void setAuthUser(AppUser? user) {
    final current = _user;
    final sameUid = current?.uid == user?.uid;
    final sameAnon = current?.isAnonymous == user?.isAnonymous;
    if (sameUid && sameAnon) return;
    _user = user;
    if (user == null) {
      isCheckingCommunityProfile = false;
      isCommunityProfileComplete = true;
      notifyListeners();
      return;
    }

    isCheckingCommunityProfile = true;
    notifyListeners();

    Future(() async {
      await refreshCommunityProfileStatus();
    });
  }

  Future<void> refreshCommunityProfileStatus() async {
    final uid = _user?.uid;
    if (uid == null || uid.isEmpty) {
      isCheckingCommunityProfile = false;
      isCommunityProfileComplete = true;
      notifyListeners();
      return;
    }

    isCheckingCommunityProfile = true;
    notifyListeners();

    try {
      await _communityProfileRepository.ensureCommunityProfileExists(uid);
      final complete = await _communityProfileRepository.isProfileComplete(uid);

      if (_user?.uid != uid) return;
      isCommunityProfileComplete = complete;
    } catch (_) {
      if (_user?.uid != uid) return;
      isCommunityProfileComplete = false;
    } finally {
      if (_user?.uid == uid) {
        isCheckingCommunityProfile = false;
        notifyListeners();
      }
    }
  }

  void toggleFeedLanguageFilter() {
    showOnlyMyLanguages = !showOnlyMyLanguages;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      await _authService.registerWithEmail(email, password);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<void> refreshUser() async {
    await _authService.reloadUser();
  }
}
