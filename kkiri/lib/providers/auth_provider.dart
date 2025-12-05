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

  Future<void> _ensureUserProfile(User user) async {
    final doc = _db.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set({
      'displayName': user.displayName ?? 'Heart_${user.uid.substring(0, 6)}',
      'photoUrl': user.photoURL,
      'bio': '새로운 인연을 찾아요!',
      'age': null,
      'gender': null,
      'interests': <String>[],
      'likesSent': <String>[],
      'likesReceived': <String>[],
      'matches': <String>[],
      'passes': <String>[],
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'lang': 'ko',
      'searchId': user.uid.substring(0, 6),
    });
  }

  String _messageForAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '가입된 이메일을 찾을 수 없습니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'invalid-email':
        return '유효한 이메일을 입력해주세요.';
      case 'account-exists-with-different-credential':
        return '다른 인증 방법으로 가입된 계정이 있습니다.';
      case 'user-disabled':
        return '이 계정은 비활성화되었습니다.';
      default:
        return e.message ?? '로그인 중 문제가 발생했습니다. Firebase 구성을 확인해주세요.';
    }
  }

  Future<bool> signInWithEmail({required String email, required String password}) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      currentUser = cred.user;
      if (currentUser != null) {
        await _ensureUserProfile(currentUser!);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _messageForAuthException(e);
      return false;
    } catch (e) {
      lastError = '로그인 중 문제가 발생했습니다. 인터넷 연결과 Firebase 구성을 확인해주세요.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerWithEmail({required String email, required String password}) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      currentUser = cred.user;
      if (currentUser != null) {
        await _ensureUserProfile(currentUser!);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _messageForAuthException(e);
      return false;
    } catch (e) {
      lastError = '회원가입 중 문제가 발생했습니다. 인터넷 연결과 Firebase 구성을 확인해주세요.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithLine() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      final provider = OAuthProvider('oidc.line');
      final cred = await _auth.signInWithProvider(provider);
      currentUser = cred.user;
      if (currentUser != null) {
        await _ensureUserProfile(currentUser!);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _messageForAuthException(e);
      return false;
    } catch (e) {
      lastError = '라인 인증 중 문제가 발생했습니다. 설정을 확인해주세요.';
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
