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
  bool verificationEmailSent = false;

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

  Future<void> _ensureUserDocument(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) return;

    await docRef.set({
      'displayName': user.displayName ?? 'Heart_${user.uid.substring(0, 6)}',
      'photoUrl': user.photoURL,
      'bio': '새로운 인연을 찾아요!',
      'age': null,
      'gender': null,
      'country': null,
      'interests': <String>[],
      'photos': <String>[],
      'likesSent': <String>[],
      'likesReceived': <String>[],
      'matches': <String>[],
      'passes': <String>[],
      'friends': <String>[],
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'lang': 'ko',
      'searchId': user.uid.substring(0, 6),
      'preferredCountries': <String>[],
      'shareLocation': true,
    });
  }

  Future<bool> signInAnonymously() async {
    isLoading = true;
    lastError = null;
    verificationEmailSent = false;
    notifyListeners();
    try {
      final cred = await _auth.signInAnonymously();
      currentUser = cred.user;
      if (currentUser != null) {
        await _ensureUserDocument(currentUser!);
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

  Future<bool> sendVerificationEmail(String email, String password) async {
    isLoading = true;
    lastError = null;
    verificationEmailSent = false;
    notifyListeners();
    try {
      UserCredential cred;
      try {
        cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        } else {
          rethrow;
        }
      }

      currentUser = cred.user;
      if (currentUser != null) {
        await _ensureUserDocument(currentUser!);
        await currentUser!.sendEmailVerification();
        verificationEmailSent = true;
        await _auth.signOut();
        currentUser = null;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? '이메일 인증을 보내지 못했습니다.';
      return false;
    } catch (e) {
      lastError = '이메일 인증을 보내지 못했습니다. 잠시 후 다시 시도해주세요.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    isLoading = true;
    lastError = null;
    verificationEmailSent = false;
    notifyListeners();
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      currentUser = cred.user;
      if (currentUser == null) {
        lastError = '로그인에 실패했습니다.';
        return false;
      }

      await currentUser!.reload();
      if (!(currentUser!.emailVerified)) {
        await currentUser!.sendEmailVerification();
        verificationEmailSent = true;
        lastError = '이메일 인증이 필요합니다. 메일함을 확인해주세요.';
        await _auth.signOut();
        currentUser = null;
        return false;
      }

      await _ensureUserDocument(currentUser!);
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? '로그인 중 문제가 발생했습니다.';
      return false;
    } catch (e) {
      lastError = '로그인 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
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
    String? gender,
    String? country,
    List<String>? preferredCountries,
    bool? shareLocation,
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
    if (gender != null) data['gender'] = gender;
    if (country != null) data['country'] = country;
    if (preferredCountries != null) data['preferredCountries'] = preferredCountries;
    if (shareLocation != null) data['shareLocation'] = shareLocation;
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
