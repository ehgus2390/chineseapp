import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;

  User? currentUser;
  bool isLoading = false;

  AuthProvider() {
    currentUser = _auth.currentUser;
    _listenAuthState();
  }

  void _listenAuthState() {
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen((user) {
      currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signInAnonymously() async {
    isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.signInAnonymously();
      currentUser = cred.user;
      if (currentUser != null) {
        final doc = _db.collection('users').doc(currentUser!.uid);
        final snapshot = await doc.get();
        if (!snapshot.exists) {
          await doc.set({
            'displayName': 'User_${currentUser!.uid.substring(0, 6)}',
            'photoUrl': null,
            'email': currentUser!.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lang': 'ko',
            'friends': [],
            'searchId': currentUser!.uid.substring(0, 6),
            'age': null,
            'gender': null,
            'bio': null,
            'interests': <String>[],
            'preferredCountries': <String>[],
            'preferredLanguages': <String>[],
            'notifyChat': true,
            'notifyComment': true,
            'notifyLike': true,
          });
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<bool> upgradeToEmailAccount(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final linked = await user.linkWithCredential(credential);
      currentUser = linked.user;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        await _auth.signInWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        currentUser = _auth.currentUser;
        notifyListeners();
        return true;
      }
      rethrow;
    }
  }

  Future<bool> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    await user.sendEmailVerification();
    return true;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await currentUser?.updatePhotoURL(photoUrl);
    await _db.collection('users').doc(uid).update({'photoUrl': photoUrl});
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? searchId,
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
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    final data = <String, dynamic>{};
    if (displayName != null) {
      data['displayName'] = displayName;
      await currentUser?.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
      await currentUser?.updatePhotoURL(photoUrl);
    }
    if (searchId != null) data['searchId'] = searchId;
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
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
      notifyListeners();
    }
  }

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

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
