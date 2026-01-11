import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../models/profile.dart';
import '../services/match_service.dart';
import 'app_state.dart';

class EligibleProfilesProvider extends ChangeNotifier {
  EligibleProfilesProvider({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance {
    _controller.add(<Profile>[]);
    _usersSub = _db.collection('users').snapshots().listen(
      _handleUsers,
      onError: (error) {
        debugPrint('watchCandidates error: $error');
        debugPrint('watchNearbyUsers error: $error');
        _controller.addError(error);
      },
    );
  }

  final FirebaseFirestore _db;
  final MatchService _matchService = MatchService();
  final StreamController<List<Profile>> _controller =
      StreamController<List<Profile>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  List<Profile> _allUsers = <Profile>[];
  Profile? _me;
  Set<String> _likedIds = <String>{};
  Set<String> _passedIds = <String>{};
  List<MatchPair> _matches = <MatchPair>[];
  bool _distanceFilterEnabled = true;
  List<String> _preferredLanguages = <String>[];

  Stream<List<Profile>> get stream => _controller.stream;

  void updateFromAppState(AppState state) {
    _me = state.meOrNull;
    _likedIds = state.likedIds;
    _passedIds = state.passedIds;
    _matches = state.matches;
    _distanceFilterEnabled = state.distanceFilterEnabled;
    _preferredLanguages = state.myPreferredLanguages;
    _emitEligible();
  }

  void _handleUsers(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _allUsers = snapshot.docs.map(Profile.fromDoc).toList();
    _emitEligible();
  }

  void _emitEligible() {
    if (_me == null || !isProfileComplete(_me!)) {
      _controller.add(<Profile>[]);
      return;
    }
    final eligible = applyEligibility(
      me: _me!,
      allUsers: _allUsers,
      distanceFilterEnabled: _distanceFilterEnabled,
    );
    eligible.sort((a, b) {
      final double scoreB = _matchService.score(_me!, b, _preferredLanguages);
      final double scoreA = _matchService.score(_me!, a, _preferredLanguages);
      return scoreB.compareTo(scoreA);
    });
    _controller.add(eligible);
  }

  List<Profile> applyEligibility({
    required Profile me,
    required List<Profile> allUsers,
    required bool distanceFilterEnabled,
  }) {
    final matchesIds = _matches.expand((m) => m.userIds).toSet();
    return allUsers
        .where((p) =>
            isProfileComplete(p) &&
            p.id != me.id &&
            isOppositeGender(me, p) &&
            hasCommonInterest(me, p) &&
            _passesDistanceFilter(me, p, distanceFilterEnabled) &&
            !_likedIds.contains(p.id) &&
            !_passedIds.contains(p.id) &&
            !matchesIds.contains(p.id))
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
      Profile me, Profile other, bool distanceFilterEnabled) {
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
    final double h = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    return radius * 2 * asin(sqrt(h));
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  @override
  void dispose() {
    _usersSub?.cancel();
    _controller.close();
    super.dispose();
  }
}
