import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/match.dart';
import '../models/profile.dart';
import '../services/chat_service.dart';
import '../services/match_service.dart';
import '../services/preferences_storage.dart';

class AppState extends ChangeNotifier {
  AppState() {
    chat = ChatService(_db);
    _authSub = _auth.authStateChanges().listen(_handleAuthChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final MatchService _matchService = MatchService();
  final PreferencesStorage _preferences = PreferencesStorage.instance;

  late final ChatService chat;

  Profile? _me;
  final Map<String, Profile> _profiles = <String, Profile>{};
  final List<MatchPair> _matches = <MatchPair>[];
  final List<String> _preferredLanguages = <String>[];
  final Set<String> _likedIds = <String>{};
  final Set<String> _passedIds = <String>{};

  bool _isOnboarded = false;
  bool _initialized = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _meSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _matchesSub;
  StreamSubscription<User?>? _authSub;

  static const String _onboardingKey = 'onboarding_complete';
  static const String _preferredLanguagesKey = 'preferred_languages';

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null && !user!.isAnonymous;

  bool get isOnboarded => _isOnboarded;
  Profile get me => _me!;
  Profile? get meOrNull => _me;
  List<MatchPair> get matches => List<MatchPair>.unmodifiable(_matches);
  List<String> get myPreferredLanguages =>
      List<String>.unmodifiable(_preferredLanguages);

  Future<void> bootstrap() async {
    if (_initialized) return;
    _initialized = true;

    await _restorePersistentState();
  }
  
  Future<void> _handleAuthChanged(User? user) async {
    if (user == null || user.isAnonymous) {
      if (user?.isAnonymous == true) {
        await _auth.signOut();
      }
      _me = null;
      _profiles.clear();
      _matches.clear();
      _likedIds.clear();
      _passedIds.clear();
      await _meSub?.cancel();
      await _matchesSub?.cancel();
      notifyListeners();
      return;
    }
    await _ensureProfile();
    await _loadMeOnce();
    await _loadMyDecisions();
    _watchMyProfile();
    _watchMatches();
    notifyListeners();
  }

  Future<void> _ensureProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final doc = _db.collection('users').doc(currentUser.uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set(<String, dynamic>{
      'name': currentUser.displayName ?? 'New user',
      'age': 0,
      'occupation': '',
      'country': '',
      'interests': <String>[],
      'gender': 'male',
      'languages': <String>['ko'],
      'bio': '',
      'avatarUrl': currentUser.photoURL ?? '',
      'distanceKm': 30,
      'location': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadMeOnce() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final doc = await _db.collection('users').doc(currentUser.uid).get();
    if (!doc.exists) return;
    _me = Profile.fromDoc(doc);
    _profiles[_me!.id] = _me!;
    if (_preferredLanguages.isEmpty) {
      _preferredLanguages
        ..clear()
        ..addAll(_me!.languages);
    }
    notifyListeners();
  }

  void _watchMyProfile() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    _meSub?.cancel();
    _meSub = _db.collection('users').doc(currentUser.uid).snapshots().listen(
      (doc) {
        _me = Profile.fromDoc(doc);
        _profiles[_me!.id] = _me!;
        notifyListeners();
      },
    );
  }

  void _watchMatches() {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    _matchesSub?.cancel();
    _matchesSub = _db
        .collection('matches')
        .where('userIds', arrayContains: meProfile.id)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _matches
        ..clear()
        ..addAll(snapshot.docs.map(MatchPair.fromDoc));
      notifyListeners();
    });
  }

  Future<void> _restorePersistentState() async {
    final bool storedOnboarding =
        await _preferences.readBool(_onboardingKey) ?? false;
    _isOnboarded = storedOnboarding;

    final List<String>? storedLanguages =
        await _preferences.readStringList(_preferredLanguagesKey);
    if (storedLanguages != null && storedLanguages.isNotEmpty) {
      _preferredLanguages
        ..clear()
        ..addAll(storedLanguages);
    }

    notifyListeners();
  }

  Future<void> _loadMyDecisions() async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    final likesSnap =
        await _db.collection('users').doc(meProfile.id).collection('likes').get();
    _likedIds
      ..clear()
      ..addAll(likesSnap.docs.map((doc) => doc.id));

    final passesSnap =
        await _db.collection('users').doc(meProfile.id).collection('passes').get();
    _passedIds
      ..clear()
      ..addAll(passesSnap.docs.map((doc) => doc.id));
    notifyListeners();
  }

  Stream<List<Profile>> watchCandidates() {
    final Profile? meProfile = _me;
    if (meProfile == null) {
      return const Stream<List<Profile>>.empty();
    }
    final String targetGender =
        meProfile.gender == 'female' ? 'male' : 'female';
    final matchesIds = _matches.expand((m) => m.userIds).toSet();
    return _db
        .collection('users')
        .where('gender', isEqualTo: targetGender)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Profile.fromDoc).toList())
        .map((list) {
      final filtered = list
          .where((p) =>
              p.id != meProfile.id &&
              p.gender == targetGender &&
              _sharesInterests(meProfile, p) &&
              !_likedIds.contains(p.id) &&
              !_passedIds.contains(p.id) &&
              !matchesIds.contains(p.id))
          .where((p) => _withinDistance(p, meProfile))
          .toList();
      filtered.sort((a, b) {
        final double scoreB =
            _matchService.score(meProfile, b, _preferredLanguages);
        final double scoreA =
            _matchService.score(meProfile, a, _preferredLanguages);
        return scoreB.compareTo(scoreA);
      });
      return filtered;
    });
  }

  bool _sharesInterests(Profile meProfile, Profile other) {
    if (meProfile.interests.isEmpty) return true;
    if (other.interests.isEmpty) return false;
    return other.interests.any(meProfile.interests.contains);
  }

  bool _withinDistance(Profile other, Profile meProfile) {
    if (meProfile.location == null || other.location == null) return true;
    final double limit =
        meProfile.distanceKm <= 0 ? double.infinity : meProfile.distanceKm;
    final double distance = _distanceKm(meProfile.location!, other.location!);
    return distance <= limit;
  }

  double? distanceKmTo(Profile other) {
    if (_me?.location == null || other.location == null) return null;
    return _distanceKm(_me!.location!, other.location!);
  }

  double _distanceKm(GeoPoint a, GeoPoint b) {
    const double radius = 6371;
    final double dLat = _deg2rad(b.latitude - a.latitude);
    final double dLon = _deg2rad(b.longitude - a.longitude);
    final double lat1 = _deg2rad(a.latitude);
    final double lat2 = _deg2rad(b.latitude);
    final double h = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    return radius * 2 * asin(sqrt(h));
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  Future<void> like(Profile profile) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;

    _likedIds.add(profile.id);
    await _db
        .collection('users')
        .doc(meProfile.id)
        .collection('likes')
        .doc(profile.id)
        .set(<String, dynamic>{'createdAt': FieldValue.serverTimestamp()});

    final reciprocal = await _db
        .collection('users')
        .doc(profile.id)
        .collection('likes')
        .doc(meProfile.id)
        .get();
    if (reciprocal.exists) {
      await _createMatch(meProfile.id, profile.id);
    }

    notifyListeners();
  }

  Future<void> pass(Profile profile) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;

    _passedIds.add(profile.id);
    await _db
        .collection('users')
        .doc(meProfile.id)
        .collection('passes')
        .doc(profile.id)
        .set(<String, dynamic>{'createdAt': FieldValue.serverTimestamp()});
    notifyListeners();
  }

  Future<void> _createMatch(String meId, String otherId) async {
    final List<String> ids = <String>[meId, otherId]..sort();
    final String matchId = ids.join('_');
    await _db.collection('matches').doc(matchId).set(<String, dynamic>{
      'userIds': ids,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Profile?> fetchProfile(String id) async {
    if (_profiles.containsKey(id)) return _profiles[id];
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    final profile = Profile.fromDoc(doc);
    _profiles[id] = profile;
    return profile;
  }

  Future<void> completeOnboarding() async {
    if (_isOnboarded) return;
    _isOnboarded = true;
    await _preferences.writeBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> setPreferredLanguage(String code, bool enabled) async {
    if (enabled) {
      if (!_preferredLanguages.contains(code)) {
        _preferredLanguages.add(code);
      }
    } else {
      _preferredLanguages.remove(code);
    }

    await _persistPreferredLanguages();
    notifyListeners();
  }

  Future<void> savePreferredLanguages() => _persistPreferredLanguages();

  Future<void> _persistPreferredLanguages() =>
      _preferences.writeStringList(_preferredLanguagesKey, _preferredLanguages);

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    notifyListeners();
  }

  Future<void> saveProfile({
    required String name,
    required int age,
    required String occupation,
    required String country,
    required List<String> interests,
    required String gender,
    required List<String> languages,
    required String bio,
    required double distanceKm,
    required GeoPoint? location,
  }) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    await _db.collection('users').doc(meProfile.id).set(<String, dynamic>{
      'name': name,
      'age': age,
      'occupation': occupation,
      'country': country,
      'interests': interests,
      'gender': gender,
      'languages': languages,
      'bio': bio,
      'distanceKm': distanceKm,
      'location': location,
    }, SetOptions(merge: true));
  }

  Future<void> updateMatchPreferences({
    required double distanceKm,
    required GeoPoint? location,
  }) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    await _db.collection('users').doc(meProfile.id).set(<String, dynamic>{
      'distanceKm': distanceKm,
      'location': location,
    }, SetOptions(merge: true));
  }

  Future<void> uploadAvatar(Uint8List data) async {
    final User? currentUser = user;
    if (currentUser == null) {
      throw StateError('Cannot upload avatar without signing in.');
    }

    final Reference ref = _storage.ref().child('avatars/${currentUser.uid}.jpg');
    await ref.putData(data);
    final String url = await ref.getDownloadURL();
    await _db.collection('users').doc(currentUser.uid).update(<String, Object?>{
      'avatarUrl': url,
    });
  }

  @override
  void dispose() {
    _meSub?.cancel();
    _matchesSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
