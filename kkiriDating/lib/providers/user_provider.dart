import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile.dart';
import '../state/app_state.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(this._appState) {
    _syncFromAppState();
    _appState.addListener(_syncFromAppState);
  }

  final AppState _appState;
  Profile? _me;

  Profile? get me => _me;

  void _syncFromAppState() {
    final next = _appState.meOrNull;
    if (identical(next, _me)) return;
    _me = next;
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
    await _appState.saveProfile(
      name: name,
      age: age,
      occupation: occupation,
      country: country,
      interests: interests,
      gender: gender,
      languages: languages,
      bio: bio,
      distanceKm: distanceKm,
      location: location,
    );
    _syncFromAppState();
  }

  @override
  void dispose() {
    _appState.removeListener(_syncFromAppState);
    super.dispose();
  }
}
