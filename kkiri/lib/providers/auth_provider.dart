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
            'searchId': currentUser!.uid.substring(0, 6),
          });
        }
      }
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
