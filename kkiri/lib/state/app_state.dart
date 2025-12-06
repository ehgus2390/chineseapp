import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  User? currentUser;

  void setUser(User? user) {
    currentUser = user;
    notifyListeners();
  }
}