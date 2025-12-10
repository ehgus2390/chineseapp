// lib/state/app_state.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  AppState({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _subscription = _authService.onAuthChanged().listen((authUser) {
      user = authUser;
      isLoading = false;
      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  User? user;
  bool isLoading = true;

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
