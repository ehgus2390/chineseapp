// lib/providers/auth_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<fb.User?>? _authSub;
  fb.User? currentUser;

  bool isLoading = false;
  String? lastError;

  AuthProvider() {
    currentUser = _auth.currentUser;
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(fb.User? user) {
    currentUser = user;
    _schedulePostAuthWork(user);
    notifyListeners();
  }

  void _schedulePostAuthWork(fb.User? user) {
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) return;

    Future(() async {
      await _migrateLanguageFields(uid);
    });
  }

  /// 사용자 언어 필드 마이그레이션
  Future<void> _migrateLanguageFields(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};

    // 기존 필드가 존재하면 마이그레이션 건너뜀
    if (data.containsKey('languages') && data.containsKey('mainLanguage')) {
      return;
    }

    final List<String> languages = [];

    final preferred = data['preferredLanguages'];
    final lang = data['lang'];

    if (preferred is List && preferred.isNotEmpty) {
      languages.addAll(preferred.cast<String>());
    } else if (lang is String && lang.isNotEmpty) {
      languages.add(lang);
    } else {
      languages.add('ko'); // 기본 언어
    }

    final mainLanguage = languages.first;

    await ref.set({
      'languages': languages.toSet().toList(),
      'mainLanguage': mainLanguage,
    }, SetOptions(merge: true));
  }

  /// 익명 로그인
  Future<bool> signInAnonymously() async {
    final u = await signInAnonymouslyUser();
    return u != null;
  }

  Future<fb.User?> signInAnonymouslyUser() async {
    try {
      final cred = await _auth.signInAnonymously();
      currentUser = cred.user;
      if (currentUser == null) return null;

      final user = currentUser;
      if (user == null) {
        lastError = 'User not available after anonymous sign-in.';
        return null;
      }
      final ref = _db.collection('users').doc(user.uid);
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({
          'displayName': 'User_${user.uid.substring(0, 6)}',
          'photoUrl': null,
          'languages': ['ko'],
          'mainLanguage': 'ko',
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'searchId': user.uid.substring(0, 6),
          'age': null,
          'gender': null,
          'bio': null,
          'interests': [],
          'preferredCountries': [],
          'notifyChat': true,
          'notifyComment': true,
          'notifyLike': true,
        }, SetOptions(merge: true));
      } else {
        await _migrateLanguageFields(user.uid);
      }

      notifyListeners();
      return currentUser;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  bool requireVerified(BuildContext context, String featureName) {
    if (isEmailVerified) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$featureName 기능은 이메일 인증이 필요합니다. 이메일 인증 후 다시 시도해주세요.',
        ),
      ),
    );
    return false;
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    List<String>? languages,
    String? mainLanguage,
    int? age,
    String? gender,
    String? bio,
    List<String>? interests,
    List<String>? preferredCountries,
    bool? notifyChat,
    bool? notifyComment,
    bool? notifyLike,
    bool? shareLocation,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final data = <String, dynamic>{};

    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (languages != null) data['languages'] = languages;
    if (mainLanguage != null) data['mainLanguage'] = mainLanguage;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (bio != null) data['bio'] = bio;
    if (interests != null) data['interests'] = interests;
    if (preferredCountries != null) {
      data['preferredCountries'] = preferredCountries;
    }
    if (notifyChat != null) data['notifyChat'] = notifyChat;
    if (notifyComment != null) data['notifyComment'] = notifyComment;
    if (notifyLike != null) data['notifyLike'] = notifyLike;
    if (shareLocation != null) data['shareLocation'] = shareLocation;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
