import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  User? currentUser;
  bool isLoading = false;

  void listenAuthState() {
    _auth.authStateChanges().listen((user) {
      currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signInAnonymously() async {
    isLoading = true; notifyListeners();
    try {
      final cred = await _auth.signInAnonymously();
      currentUser = cred.user;
      // 최소 프로필 문서 생성
      if (currentUser != null) {
        final doc = _db.collection('users').doc(currentUser!.uid);
        final snapshot = await doc.get();
        if (!snapshot.exists) {
          await doc.set({
            'displayName': 'User_${currentUser!.uid.substring(0,6)}',
            'photoUrl': null,
            'email': null,
            'createdAt': FieldValue.serverTimestamp(),
            'lang': 'ko',
            'friends': [],
            'searchId': currentUser!.uid.substring(0,6), // 초기값: uid 앞6자리
          });
        }
      }
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({String? displayName, String? photoUrl, String? searchId, String? lang}) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (searchId != null) data['searchId'] = searchId;
    if (lang != null) data['lang'] = lang;
    if (data.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
      notifyListeners();
    }
  }
}
