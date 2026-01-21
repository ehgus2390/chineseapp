import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/match_session.dart' as session_model;
import '../models/profile.dart';
import '../services/chat_service.dart';
import '../services/preferences_storage.dart';

enum MatchMode { direct, auto }

class AppState extends ChangeNotifier {
  AppState() {
    chat = ChatService(_db);
    _authSub = _auth.authStateChanges().listen(_handleAuthChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final PreferencesStorage _preferences = PreferencesStorage.instance;

  late final ChatService chat;

  Profile? _me;
  final Map<String, Profile> _profiles = <String, Profile>{};
  final Map<String, session_model.MatchSession> _matchSessions =
      <String, session_model.MatchSession>{};
  final List<String> _preferredLanguages = <String>[];
  final Set<String> _likedIds = <String>{};
  final Set<String> _passedIds = <String>{};
  final Set<String> _loggedEventKeys = <String>{};

  bool _isOnboarded = false;
  bool _initialized = false;
  bool _distanceFilterEnabled = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _meSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _matchSessionsSubA;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _matchSessionsSubB;
  StreamSubscription<User?>? _authSub;

  Stream<session_model.MatchSession?> watchMatchSession(String otherUserId) {
    final Profile? meProfile = _me;
    if (meProfile == null) {
      return Stream.value(null);
    }

    final String matchId = _matchIdFor(otherUserId);

    return _db.collection('match_sessions').doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return session_model.MatchSession.fromDoc(doc);
    });
  }

  static const String _onboardingKey = 'onboarding_complete';
  static const String _preferredLanguagesKey = 'preferred_languages';
  static const String _distanceFilterEnabledKey = 'distance_filter_enabled';

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null && !user!.isAnonymous;

  bool get isOnboarded => _isOnboarded;
  Profile get me => _me!;
  Profile? get meOrNull => _me;
  Set<String> get matchedUserIds => Set<String>.unmodifiable(_matchedUserIds);
  final Set<String> _matchedUserIds = <String>{};
  List<String> get myPreferredLanguages =>
      List<String>.unmodifiable(_preferredLanguages);
  Set<String> get likedIds => Set<String>.unmodifiable(_likedIds);
  Set<String> get passedIds => Set<String>.unmodifiable(_passedIds);
  bool get distanceFilterEnabled => _distanceFilterEnabled;

  bool isProfileReady(Profile profile) {
    final String gender = profile.gender.trim().toLowerCase();
    final bool genderValid = gender == 'male' || gender == 'female';
    return profile.name.trim().isNotEmpty &&
        profile.age > 0 &&
        genderValid &&
        profile.interests.isNotEmpty &&
        profile.photoUrl != null &&
        profile.photoUrl!.trim().isNotEmpty;
  }

  bool isOppositeGender(Profile me, Profile other) {
    final String meGender = me.gender.trim().toLowerCase();
    final String otherGender = other.gender.trim().toLowerCase();
    final bool meValid = meGender == 'male' || meGender == 'female';
    final bool otherValid = otherGender == 'male' || otherGender == 'female';
    return meValid && otherValid && meGender != otherGender;
  }

  bool hasCommonInterest(Profile me, Profile other) {
    if (me.interests.isEmpty || other.interests.isEmpty) return false;
    return other.interests.any(me.interests.contains);
  }

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
      _matchSessions.clear();
      _matchedUserIds.clear();
      _likedIds.clear();
      _passedIds.clear();
      await _meSub?.cancel();
      await _matchSessionsSubA?.cancel();
      await _matchSessionsSubB?.cancel();
      notifyListeners();
      return;
    }
    await _ensureProfile();
    await _syncAuthFields(user);
    await _loadMeOnce();
    await _loadMyDecisions();
    _watchMyProfile();
    _watchMatchSessions();
    notifyListeners();
  }

  Future<void> _ensureProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final doc = _db.collection('users').doc(currentUser.uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set(<String, dynamic>{
      'userId': currentUser.uid,
      'email': currentUser.email ?? '',
      'name': currentUser.displayName ?? 'New user',
      'age': 0,
      'occupation': '',
      'country': '',
      'interests': <String>[],
      'gender': 'male',
      'languages': <String>['ko'],
      'bio': '',
      'distanceKm': 30,
      'location': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _syncAuthFields(User user) async {
    await _db.collection('users').doc(user.uid).set(<String, dynamic>{
      'userId': user.uid,
      'email': user.email ?? '',
    }, SetOptions(merge: true));
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
    _meSub = _db.collection('users').doc(currentUser.uid).snapshots().listen((
      doc,
    ) {
      _me = Profile.fromDoc(doc);
      _profiles[_me!.id] = _me!;
      notifyListeners();
    });
  }

  void _watchMatchSessions() {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    _matchSessionsSubA?.cancel();
    _matchSessionsSubB?.cancel();
    _matchSessionsSubA = _db
        .collection('match_sessions')
        .where('userA', isEqualTo: meProfile.id)
        .snapshots()
        .listen(_handleMatchSessionsSnapshot);
    _matchSessionsSubB = _db
        .collection('match_sessions')
        .where('userB', isEqualTo: meProfile.id)
        .snapshots()
        .listen(_handleMatchSessionsSnapshot);
  }

  void _handleMatchSessionsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        _matchSessions.remove(change.doc.id);
      } else {
        _matchSessions[change.doc.id] = session_model.MatchSession.fromDoc(
          change.doc,
        );
      }
    }
    _rebuildMatchedUserIds();
    notifyListeners();
  }

  void _rebuildMatchedUserIds() {
    _matchedUserIds
      ..clear()
      ..addAll(
        _matchSessions.values
            .where((session) {
              return session.status == session_model.MatchStatus.accepted;
            })
            .map((session) {
              return session.userA == _me?.id ? session.userB : session.userA;
            }),
      );
  }

  Future<void> _restorePersistentState() async {
    final bool storedOnboarding =
        await _preferences.readBool(_onboardingKey) ?? false;
    _isOnboarded = storedOnboarding;

    final List<String>? storedLanguages = await _preferences.readStringList(
      _preferredLanguagesKey,
    );
    if (storedLanguages != null && storedLanguages.isNotEmpty) {
      _preferredLanguages
        ..clear()
        ..addAll(storedLanguages);
    }
    final bool? storedDistanceEnabled = await _preferences.readBool(
      _distanceFilterEnabledKey,
    );
    if (storedDistanceEnabled != null) {
      _distanceFilterEnabled = storedDistanceEnabled;
    }

    notifyListeners();
  }

  Future<void> _loadMyDecisions() async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    final likesSnap = await _db
        .collection('users')
        .doc(meProfile.id)
        .collection('likes')
        .get();
    _likedIds
      ..clear()
      ..addAll(likesSnap.docs.map((doc) => doc.id));

    final passesSnap = await _db
        .collection('users')
        .doc(meProfile.id)
        .collection('passes')
        .get();
    _passedIds
      ..clear()
      ..addAll(passesSnap.docs.map((doc) => doc.id));
    notifyListeners();
  }

  Future<void> ensureChatRoomForSession(String sessionId) async {
    final DocumentReference<Map<String, dynamic>> sessionRef = _db
        .collection('match_sessions')
        .doc(sessionId);
    final DocumentReference<Map<String, dynamic>> roomRef = _db
        .collection('chat_rooms')
        .doc(sessionId);

    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(sessionRef);
      if (!sessionSnap.exists) return;
      final data = sessionSnap.data() ?? <String, dynamic>{};
      if (data['status']?.toString() != 'accepted') return;

      final String userA = (data['userA'] ?? '').toString();
      final String userB = (data['userB'] ?? '').toString();
      final List<String> participants = <String>[
        userA,
        userB,
      ].where((id) => id.trim().isNotEmpty).toList();
      final String? mode = data['mode']?.toString();

      final roomSnap = await tx.get(roomRef);
      if (roomSnap.exists) return;
      final Map<String, dynamic> payload = <String, dynamic>{
        'participants': participants,
        'sessionId': sessionId,
        'mode': mode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
        'isActive': true,
      };
      // Transaction keeps room creation idempotent under concurrent callers.
      tx.set(roomRef, payload, SetOptions(merge: true));
    });
  }

  Future<void> logEvent({
    required String type,
    required String sessionId,
    required String mode,
    required String otherUserId,
  }) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    final String key = '$type|$sessionId|${meProfile.id}';
    if (_loggedEventKeys.contains(key)) return;
    _loggedEventKeys.add(key);
    try {
      await _db.collection('analytics_events').add(<String, dynamic>{
        'type': type,
        'sessionId': sessionId,
        'mode': mode,
        'userId': meProfile.id,
        'otherUserId': otherUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort logging: ignore analytics errors.
    }
  }

  Future<void> logFirstMessageSent({
    required String sessionId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _db.collection('match_sessions').doc(sessionId).get();
      if (!doc.exists) return;
      final data = doc.data() ?? <String, dynamic>{};
      final String? mode = data['mode']?.toString();
      if (mode == null) return;
      await logEvent(
        type: 'first_message_sent',
        sessionId: sessionId,
        mode: mode,
        otherUserId: otherUserId,
      );
    } catch (_) {
      // Best-effort logging: ignore analytics errors.
    }
  }

  Future<session_model.MatchSession> ensureMatchSession({
    required String otherUserId,
    required MatchMode mode,
  }) async {
    final Profile? meProfile = _me;
    if (meProfile == null) {
      throw StateError('No signed-in user.');
    }
    if (otherUserId == meProfile.id) {
      throw ArgumentError('Cannot match with self.');
    }

    final List<String> ids = <String>[meProfile.id, otherUserId]..sort();
    final String matchId = ids.join('_');
    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('match_sessions')
        .doc(matchId);

    return _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (snapshot.exists) {
        return session_model.MatchSession.fromDoc(snapshot);
      }
      final bool isDirect = mode == MatchMode.direct;
      final DateTime now = DateTime.now();
      final DateTime? expiresAt = isDirect
          ? null
          : now.add(const Duration(minutes: 5));
      tx.set(ref, <String, dynamic>{
        'userA': ids.first,
        'userB': ids.last,
        'mode': isDirect ? 'direct' : 'auto',
        'status': isDirect ? 'accepted' : 'pending',
        'chatRoomId': null,
        'initiatedBy': meProfile.id,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': isDirect ? FieldValue.serverTimestamp() : null,
        'expiresAt': isDirect ? null : Timestamp.fromDate(expiresAt!),
      });
      return session_model.MatchSession(
        id: matchId,
        userA: ids.first,
        userB: ids.last,
        status: isDirect
            ? session_model.MatchStatus.accepted
            : session_model.MatchStatus.pending,
        chatRoomId: null,
        createdAt: now,
        respondedAt: isDirect ? now : null,
        expiresAt: expiresAt,
        mode: isDirect ? 'direct' : 'auto',
      );
    });
  }

  Future<void> enterAutoMatchQueue() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      throw StateError('No signed-in user.');
    }

    final String userId = currentUser.uid;
    final String sessionId = 'queue_$userId';
    final DateTime expiresAt = DateTime.now().add(const Duration(minutes: 5));

    await _db.collection('match_sessions').doc(sessionId).set(
      <String, dynamic>{
        'userA': userId,
        'userB': '',
        'mode': 'auto',
        'status': 'searching',
        'chatRoomId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
        'expiresAt': Timestamp.fromDate(expiresAt),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setMatchConsent(String otherUserId, bool ready) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    final String matchId = _matchIdFor(otherUserId);
    await _db.runTransaction((tx) async {
      final ref = _db.collection('match_sessions').doc(matchId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? <String, dynamic>{};
      if (data['status']?.toString() == 'accepted') return;
      if (ready) {
        tx.set(ref, <String, dynamic>{
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> skipMatchSession(String targetUserId) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    final String matchId = _matchIdFor(targetUserId);
    await _db.collection('match_sessions').doc(matchId).set(<String, dynamic>{
      'status': 'skipped',
      'respondedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    notifyListeners();
  }

  String _matchIdFor(String otherUserId) {
    final Profile? meProfile = _me;
    if (meProfile == null) {
      throw StateError('No signed-in user.');
    }
    final List<String> ids = <String>[meProfile.id, otherUserId]..sort();
    return ids.join('_');
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
    final double h =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
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
      await ensureMatchSession(otherUserId: profile.id, mode: MatchMode.direct);
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

  Future<void> setDistanceFilterEnabled(bool enabled) async {
    _distanceFilterEnabled = enabled;
    await _preferences.writeBool(_distanceFilterEnabledKey, enabled);
    notifyListeners();
  }

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

  Future<void> setNotificationsEnabled(bool enabled) async {
    final Profile? meProfile = _me;
    if (meProfile == null) return;
    await _db.collection('users').doc(meProfile.id).set(
      <String, dynamic>{
        'notificationsEnabled': enabled,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> ensureFirstMessageGuide(String matchId, String guideText) async {
    bool shouldSend = false;
    await _db.runTransaction((tx) async {
      final ref = _db.collection('chat_rooms').doc(matchId);
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      if (data['guideSent'] == true) return;
      tx.set(ref, <String, dynamic>{
        'guideSent': true,
      }, SetOptions(merge: true));
      shouldSend = true;
    });
    if (!shouldSend) return;
    await chat.send(matchId, 'system', guideText);
  }

  Future<void> uploadAvatar(Uint8List data) async {
    final User? currentUser = user;
    if (currentUser == null || currentUser.isAnonymous) {
      throw StateError('Cannot upload avatar without signing in.');
    }

    final Reference ref = _storage.ref().child(
      'profile_images/${currentUser.uid}/profile.jpg',
    );
    try {
      final task = await ref.putData(
        data,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=3600',
        ),
      );
      final String url = await task.ref.getDownloadURL();
      await _db.collection('users').doc(currentUser.uid).update(
        <String, Object?>{'photoUrl': url},
      );
    } on FirebaseException catch (e) {
      throw StateError('Upload failed: ${e.code}');
    }
  }

  @override
  void dispose() {
    _meSub?.cancel();
    _matchSessionsSubA?.cancel();
    _matchSessionsSubB?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
