import 'dart:collection';
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
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AppState extends ChangeNotifier {
  AppState();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final MatchService _matchService = MatchService();
  final PreferencesStorage _preferences = PreferencesStorage.instance;

  final ChatService chat = ChatService();

  Profile? _me;
  final Map<String, Profile> _profiles = <String, Profile>{};
  final List<Profile> _candidates = <Profile>[];
  final List<MatchPair> _matches = <MatchPair>[];
  final List<String> _preferredLanguages = <String>[];

  bool _isOnboarded = false;
  bool _initialized = false;

  static const String _onboardingKey = 'onboarding_complete';
  static const String _preferredLanguagesKey = 'preferred_languages';

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  bool get isOnboarded => _isOnboarded;
  Profile get me => _me!;
  UnmodifiableListView<MatchPair> get matches =>
      UnmodifiableListView<MatchPair>(_matches);
  UnmodifiableListView<String> get myPreferredLanguages =>
      UnmodifiableListView<String>(_preferredLanguages);

  Future<void> bootstrap() async {
    if (_initialized) return;
    _initialized = true;
    _seedMockData();
    await _restorePersistentState();
  }

  void _seedMockData() {
    if (_me != null) {
      return;
    }

    final Profile meProfile = Profile(
      id: 'me',
      name: '민준',
      nationality: 'KR',
      languages: const <String>['ko', 'en'],
      bio: 'Coffee lover looking for global friends in Seoul.',
      avatarUrl: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518',
    );

    final List<Profile> others = <Profile>[
      Profile(
        id: 'ari',
        name: 'Ari',
        nationality: 'JP',
        languages: const <String>['ja', 'en'],
        bio: 'Planning a language exchange trip to Korea this spring.',
        avatarUrl: 'https://images.unsplash.com/photo-1544723795-3fb6469f5b39',
      ),
      Profile(
        id: 'lucas',
        name: 'Lucas',
        nationality: 'US',
        languages: const <String>['en', 'es'],
        bio: 'Foodie who wants to practice Korean before visiting Seoul.',
        avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1',
      ),
      Profile(
        id: 'yuna',
        name: 'Yuna',
        nationality: 'KR',
        languages: const <String>['ko', 'zh'],
        bio: 'Looking for a buddy to explore new cafés and learn Chinese.',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      ),
    ];

    _me = meProfile;
    _profiles[meProfile.id] = meProfile;
    if (_preferredLanguages.isEmpty) {
      _preferredLanguages
        ..clear()
        ..addAll(meProfile.languages);
    }

    for (final Profile profile in others) {
      _profiles[profile.id] = profile;
      _candidates.add(profile);
    }
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

  List<Profile> sortedCandidates() {
    if (_me == null) {
      return <Profile>[];
    }

    final List<Profile> ranked = List<Profile>.from(_candidates);
    ranked.sort((Profile a, Profile b) {
      final double scoreB = _matchService.score(me, b, _preferredLanguages);
      final double scoreA = _matchService.score(me, a, _preferredLanguages);
      return scoreB.compareTo(scoreA);
    });
    return ranked;
  }

  void like(Profile profile) {
    final int index = _candidates.indexWhere((Profile p) => p.id == profile.id);
    if (index == -1) {
      return;
    }

    _candidates.removeAt(index);
    final MatchPair match = _matchService.createMatch(me.id, profile.id);
    _matches.add(match);
    notifyListeners();
  }

  void pass(Profile profile) {
    final int index = _candidates.indexWhere((Profile p) => p.id == profile.id);
    if (index == -1) {
      return;
    }

    final Profile removed = _candidates.removeAt(index);
    _candidates.add(removed);
    notifyListeners();
  }

  Profile getById(String id) {
    final Profile? profile = _profiles[id];
    if (profile == null) {
      throw StateError('Profile $id not found');
    }
    return profile;
  }

  Future<void> completeOnboarding() async {
    if (_isOnboarded) {
      return;
    }

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
    if (googleUser == null) {
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    notifyListeners();
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
}
