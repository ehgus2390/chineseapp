import 'dart:async';

import 'package:provider/provider.dart';
import 'locale_provider.dart';

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
    _authSub = _auth.authStateChanges().listen((u) async {
      currentUser = u;
      if (u != null) {
        await _migrateLanguageFields(u.uid);

        final snap = await _db.collection('users').doc(u.uid).get();
        final mainLanguage = snap.data()?['mainLanguage'];

        if (mainLanguage is String) {
          // 🔥 여기서 UI 언어 자동 설정
          // context 못 쓰므로, 나중에 main.dart에서 처리
        }
      }
      notifyListeners();
    });
  }

  /// ───────── 언어 필드 마이그레이션 (1회성) ─────────
  Future<void> _migrateLanguageFields(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};

    // 이미 새 구조면 스킵
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
      languages.add('ko'); // 기본값
    }

    final mainLanguage = languages.first;

    await ref.set({
      'languages': languages.toSet().toList(),
      'mainLanguage': mainLanguage,
    }, SetOptions(merge: true));
  }

  /// 기존 코드 호환
  Future<bool> signInAnonymously() async {
    final u = await signInAnonymouslyUser();
    return u != null;
  }

  Future<fb.User?> signInAnonymouslyUser() async {
    try {
      final cred = await _auth.signInAnonymously();
      currentUser = cred.user;
      if (currentUser == null) return null;

      final ref = _db.collection('users').doc(currentUser!.uid);
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({
          'displayName': 'User_${currentUser!.uid.substring(0, 6)}',
          'photoUrl': null,
          'languages': ['ko'],
          'mainLanguage': 'ko',
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'searchId': currentUser!.uid.substring(0, 6),
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
        await _migrateLanguageFields(currentUser!.uid);
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
          '$featureName 기능을 사용하려면 이메일 인증이 필요합니다.\n프로필에서 인증을 완료해주세요.',
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
    if (preferredCountries != null) data['preferredCountries'] = preferredCountries;
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
