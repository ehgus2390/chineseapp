import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;

  User? currentUser;
  bool isLoading = false;
  String? lastError;

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

  Future<bool> signInAnonymously() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
<<<<<<< Updated upstream
=======
      final provider = OAuthProvider('oidc.line');
      final cred = await _auth.signInWithProvider(provider);

  Future<void> signInAnonymously() async {
    isLoading = true;
    notifyListeners();
    try {
>>>>>>> Stashed changes
      final cred = await _auth.signInAnonymously();
      currentUser = cred.user;
      if (currentUser != null) {
        final doc = _db.collection('users').doc(currentUser!.uid);
        final snapshot = await doc.get();
        if (!snapshot.exists) {
          await doc.set({
            'displayName': 'Heart_${currentUser!.uid.substring(0, 6)}',
            'photoUrl': null,
            'bio': '새로운 인연을 찾아요!',
            'age': null,
            'gender': null,
            'interests': <String>[],
            'likesSent': <String>[],
            'likesReceived': <String>[],
            'matches': <String>[],
            'passes': <String>[],
            'email': currentUser!.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lang': 'ko',
<<<<<<< Updated upstream
=======
            'displayName': 'User_${currentUser!.uid.substring(0, 6)}',
            'photoUrl': null,
            'gender': null,
            'country': null,
            'email': currentUser!.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lang': 'ko',
            'friends': [],
>>>>>>> parent of ce61b44 (Require verified sign-in)
>>>>>>> Stashed changes
            'searchId': currentUser!.uid.substring(0, 6),
          });
        }
      }
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? '로그인 중 문제가 발생했습니다. Firebase 구성을 확인해주세요.';
      return false;
    } catch (e) {
      lastError = '로그인 중 문제가 발생했습니다. 인터넷 연결과 Firebase 구성을 확인해주세요.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
    String? bio,
    int? age,
    String? gender,
    List<String>? interests,
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
    if (bio != null) data['bio'] = bio;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (interests != null) data['interests'] = interests;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
