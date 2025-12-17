// lib/state/app_state.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  AppState({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _subscription = _authService.onAuthChanged().listen((fb.User? authUser) {
      user = authUser;
      isLoading = false;
      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<fb.User?>? _subscription;

  fb.User? user;
  bool isLoading = true;

  // ✅ 피드 언어 필터
  bool showOnlyMyLanguages = true;

  // 필요하면 외부에서 직접 user를 세팅할 때 사용
  void setUser(fb.User? newUser) {
    user = newUser;
    notifyListeners();
  }

  void toggleFeedLanguageFilter() {
    showOnlyMyLanguages = !showOnlyMyLanguages;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      user = await _authService.signInWithEmail(email, password);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      user = await _authService.registerWithEmail(email, password);
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
      user = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<void> refreshUser() async {
    user = await _authService.reloadUser();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
