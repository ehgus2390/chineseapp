import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;

  User? currentUser;
  bool isLoading = false;
  String? lastError;

  AuthProvider() {
    currentUser = _auth.currentUser;
    _authSub = _auth.authStateChanges().listen((u) async {
      currentUser = u;
      notifyListeners();
    });
  }

  // ───────────────────────── 익명 로그인 ─────────────────────────
  Future<bool> signInAnonymously() async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final cred = await _auth.signInAnonymously();
      currentUser = cred.user;
      if (currentUser == null) return false;

      final doc = _db.collection('users').doc(currentUser!.uid);
      final snap = await doc.get();

      if (!snap.exists) {
        await doc.set({
          'displayName': 'User_${currentUser!.uid.substring(0, 6)}',
          'photoUrl': null,
          'age': null,
          'gender': null,
          'country': null,
          'bio': null,
          'interests': <String>[],
          'preferredCountries': <String>[],
          'preferredLanguages': <String>[],
          'notifyChat': true,
          'notifyComment': true,
          'notifyLike': true,
          'shareLocation': true,
          'lang': 'ko',
          'friends': <String>[],
          'searchId': currentUser!.uid.substring(0, 6),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? '로그인 중 문제가 발생했습니다.';
      return false;
    } catch (e) {
      lastError = '로그인 중 문제가 발생했습니다: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 이메일 인증 상태는 “캐시”가 있을 수 있어서 reload로 갱신해주는 게 안전함
  Future<void> reloadUser() async {
    final u = _auth.currentUser;
    if (u == null) return;
    await u.reload();
    currentUser = _auth.currentUser;
    notifyListeners();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ───────────────── 익명 → 이메일 계정 업그레이드 ─────────────────
  Future<bool> upgradeToEmailAccount(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final credential = EmailAuthProvider.credential(email: email, password: password);

    try {
      await user.linkWithCredential(credential);
      await sendEmailVerification();
      await reloadUser();
      return true;
    } on FirebaseAuthException catch (e) {
      // 이미 다른 계정에 이 이메일이 연결되어 있으면 로그인으로 전환
      if (e.code == 'credential-already-in-use') {
        await _auth.signInWithCredential(credential);
        currentUser = _auth.currentUser;
        notifyListeners();
        return true;
      }
      rethrow;
    }
  }

  Future<bool> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.sendEmailVerification();
    return true;
  }

  // “이 기능은 인증 필요” 가드
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

  // 예전 코드에서 ensureEmailVerified를 쓰는 경우가 많아서 호환용으로 남김
  bool ensureEmailVerified(BuildContext context, {String? message}) {
    if (isEmailVerified) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ??
              '이 기능을 사용하려면 이메일 인증이 필요합니다. 프로필에서 이메일 인증을 완료해주세요.',
        ),
      ),
    );
    return false;
  }

  // ───────────────────────── 프로필 업데이트 ─────────────────────────
  Future<void> updateProfilePhoto(String photoUrl) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'photoUrl': photoUrl});
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? lang,
    int? age,
    String? gender,
    String? country,
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
    if (country != null) data['country'] = country;
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
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
