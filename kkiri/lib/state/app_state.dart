import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _auth = AuthService();
  User? user;
  bool isLoading = true;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    _auth.onAuthChanged().listen((u) {
      user = u;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    isLoading = true;
    notifyListeners();
    await _auth.signInWithEmail(email, password);
    isLoading = false;
    notifyListeners();
  }

  Future<void> registerWithEmail(String email, String password) async {
    isLoading = true;
    notifyListeners();
    await _auth.registerWithEmail(email, password);
    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool get isLoggedIn => user != null;
}
