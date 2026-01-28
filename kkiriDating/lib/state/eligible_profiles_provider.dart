import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../services/match_service.dart';
import 'app_state.dart';

class EligibleProfilesProvider extends ChangeNotifier {
  EligibleProfilesProvider({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final MatchService _matchService = MatchService();

  Profile? _me;
  Set<String> _likedIds = <String>{};
  Set<String> _passedIds = <String>{};
  Set<String> _matchedUserIds = <String>{};
  bool _distanceFilterEnabled = true;
  List<String> _preferredLanguages = <String>[];

  List<Profile> _cachedFirstPage = <Profile>[];
  DocumentSnapshot<Map<String, dynamic>>? _cachedLastDoc;
  bool _cachedHasMore = true;
  int _fetchCount = 0;

  void updateFromAppState(AppState state) {
    _me = state.meOrNull;
    _likedIds = state.likedIds;
    _passedIds = state.passedIds;
    _matchedUserIds = state.matchedUserIds;
    _distanceFilterEnabled = state.distanceFilterEnabled;
    _preferredLanguages = state.myPreferredLanguages;
  }

  List<Profile> get cachedFirstPage =>
      List<Profile>.unmodifiable(_cachedFirstPage);
  DocumentSnapshot<Map<String, dynamic>>? get cachedLastDoc => _cachedLastDoc;
  bool get cachedHasMore => _cachedHasMore;

  Future<EligiblePage> fetchEligibleProfiles({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    _fetchCount += 1;
    debugPrint('eligible fetch count: $_fetchCount');
    if (_me == null || !isProfileComplete(_me!)) {
      return EligiblePage(profiles: <Profile>[], lastDoc: null, hasMore: false);
    }

    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final docs = snap.docs;
    final users = docs.map(Profile.fromDoc).toList();
    final eligible = applyEligibility(
      me: _me!,
      allUsers: users,
      distanceFilterEnabled: _distanceFilterEnabled,
    );
    eligible.sort((a, b) {
      final double scoreB = _matchService.score(_me!, b, _preferredLanguages);
      final double scoreA = _matchService.score(_me!, a, _preferredLanguages);
      return scoreB.compareTo(scoreA);
    });

    final lastDoc = docs.isNotEmpty ? docs.last : null;
    final hasMore = docs.length == limit;

    if (startAfter == null) {
      _cachedFirstPage = eligible;
      _cachedLastDoc = lastDoc;
      _cachedHasMore = hasMore;
    }

    return EligiblePage(profiles: eligible, lastDoc: lastDoc, hasMore: hasMore);
  }

  Future<EligiblePage> fetchFirstPage({int limit = 20}) {
    return fetchEligibleProfiles(limit: limit);
  }

  Future<EligiblePage> fetchNextPage({int limit = 20}) async {
    if (_cachedLastDoc == null || !_cachedHasMore) {
      return EligiblePage(
        profiles: <Profile>[],
        lastDoc: _cachedLastDoc,
        hasMore: false,
      );
    }
    return fetchEligibleProfiles(limit: limit, startAfter: _cachedLastDoc);
  }

  List<Profile> applyEligibility({
    required Profile me,
    required List<Profile> allUsers,
    required bool distanceFilterEnabled,
  }) {
    return allUsers
        .where(
          (p) =>
              isProfileComplete(p) &&
              p.id != me.id &&
              isOppositeGender(me, p) &&
              hasCommonInterest(me, p) &&
              _passesDistanceFilter(me, p, distanceFilterEnabled) &&
              !_likedIds.contains(p.id) &&
              !_passedIds.contains(p.id) &&
              !_matchedUserIds.contains(p.id),
        )
        .toList();
  }

  bool isProfileComplete(Profile profile) {
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

  bool _passesDistanceFilter(
    Profile me,
    Profile other,
    bool distanceFilterEnabled,
  ) {
    if (!distanceFilterEnabled) return true;
    if (me.location == null || other.location == null) return true;
    if (me.distanceKm <= 0) return true;
    final double distance = _distanceKm(me.location!, other.location!);
    return distance <= me.distanceKm;
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
}

class EligiblePage {
  final List<Profile> profiles;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  EligiblePage({
    required this.profiles,
    required this.lastDoc,
    required this.hasMore,
  });
}
