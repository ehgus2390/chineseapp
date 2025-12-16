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
    _authSub = _auth.authStateChanges().listen((u) {
      currentUser = u;
      notifyListeners();
    });
  }

  /// ✅ 기존 코드 호환: bool 유지
  Future<bool> signInAnonymously() async {
    final u = await signInAnonymouslyUser();
    return u != null;
  }

  /// ✅ 새로 추가: board_screen처럼 uid가 필요한 곳에서 사용
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
          'lang': 'ko',
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'searchId': currentUser!.uid.substring(0, 6),
          'age': null,
          'gender': null,
          'bio': null,
          'interests': [],
          'preferredCountries': [],
          'preferredLanguages': [],
          'notifyChat': true,
          'notifyComment': true,
          'notifyLike': true,
        }, SetOptions(merge: true));
      }

      notifyListeners();
      return currentUser;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<bool> upgradeToEmailAccount(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final credential =
    fb.EmailAuthProvider.credential(email: email, password: password);

    try {
      await user.linkWithCredential(credential);
      await user.sendEmailVerification();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        await _auth.signInWithCredential(credential);
        currentUser = _auth.currentUser;
        notifyListeners();
        return true;
      }
      rethrow;
    }
  }

  // ───────── 인증 필요 기능 가드 (기존 화면들 호환용) ─────────
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

  Future<bool> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    await user.sendEmailVerification();
    return true;
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? lang,
    int? age,
    String? gender,
    String? bio,
    List<String>? interests,
    List<String>? preferredCountries,
    List<String>? preferredLanguages,
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
    if (lang != null) data['lang'] = lang;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (bio != null) data['bio'] = bio;
    if (interests != null) data['interests'] = interests;
    if (preferredCountries != null) data['preferredCountries'] = preferredCountries;
    if (preferredLanguages != null) data['preferredLanguages'] = preferredLanguages;
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
