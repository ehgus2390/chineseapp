import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import 'eligible_profiles_provider.dart';

enum RefreshReason { daily, locationChanged, profileUpdated, manual }

class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({
    required EligibleProfilesProvider eligibleProvider,
  }) : _eligibleProvider = eligibleProvider {
    _scheduleDailyCheck();
    _maybeRefreshOnStartup();
  }

  EligibleProfilesProvider _eligibleProvider;
  RecommendationTab _mode = RecommendationTab.recommend;
  final List<Profile> _cachedRecommendations = <Profile>[];
  DateTime? _lastUpdatedAt;
  bool _loading = false;
  Timer? _dailyTimer;

  List<Profile> get recommendations =>
      List<Profile>.unmodifiable(_cachedRecommendations);
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  bool get isLoading => _loading;
  RecommendationTab get mode => _mode;

  void updateEligibleProvider(EligibleProfilesProvider provider) {
    if (identical(_eligibleProvider, provider)) return;
    _eligibleProvider = provider;
  }

  void setMode(RecommendationTab mode) {
    if (_mode == mode) return;
    _mode = mode;
    _cachedRecommendations.clear();
    _lastUpdatedAt = null;
    notifyListeners();
  }

  Future<void> refreshRecommendations({
    required RefreshReason reason,
  }) async {
    if (reason != RefreshReason.manual && !_isRefreshDue()) {
      return;
    }
    _loading = true;
    notifyListeners();
    final result = await _eligibleProvider.fetchEligibleProfiles(
      limit: 30,
      mode: _mode,
    );
    final List<Profile> next = result.profiles;
    _cachedRecommendations
      ..clear()
      ..addAll(next);
    _lastUpdatedAt = DateTime.now();
    _loading = false;
    notifyListeners();
  }

  bool _isRefreshDue() {
    final DateTime? last = _lastUpdatedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= const Duration(hours: 24);
  }

  void _maybeRefreshOnStartup() {
    // Time-based trigger; avoids refresh tied to widget rebuilds.
    if (_lastUpdatedAt == null) {
      refreshRecommendations(reason: RefreshReason.daily);
    }
  }

  void _scheduleDailyCheck() {
    _dailyTimer?.cancel();
    _dailyTimer = Timer.periodic(const Duration(hours: 1), (_) {
      refreshRecommendations(reason: RefreshReason.daily);
    });
  }

  @override
  void dispose() {
    _dailyTimer?.cancel();
    super.dispose();
  }
}
