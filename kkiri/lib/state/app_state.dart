import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';

class AppState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  Future<void> signInWithGoogle() async {
    final cred = await GoogleAuthProvider().signIn();
    // 이후 user 정보 Firestore 저장 로직 추가 가능
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> uploadAvatar(String path) async {
    final ref = _storage.ref().child('avatars/${user!.uid}.jpg');
    await ref.putFile(File(path));
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(user!.uid).update({'avatarUrl': url});
  }

  Future<void> bootstrap() async {
    // Firestore에서 유저 데이터 불러오기
    if (user != null) {
      final doc = await _db.collection('users').doc(user!.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(user!.uid).set({
          'name': user!.displayName ?? 'User',
          'email': user!.email,
          'languages': ['ko', 'en'],
          'createdAt': DateTime.now(),
        });
      }
    }
  }
}
