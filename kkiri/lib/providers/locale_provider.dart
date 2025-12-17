import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefLocaleKey = 'app_locale';
  static const _prefManualKey = 'app_locale_manual';

  Locale? _locale;
  bool _isManuallySet = false;

  Locale? get locale => _locale;
  bool get isManuallySet => _isManuallySet;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefLocaleKey);
    _isManuallySet = prefs.getBool(_prefManualKey) ?? false;

    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// ✅ 사용자가 Settings에서 직접 변경
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    _isManuallySet = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLocaleKey, locale.languageCode);
    await prefs.setBool(_prefManualKey, true);

    notifyListeners();
  }

  /// ✅ 프로필(mainLanguage) 기반 자동 설정
  Future<void> setLocaleFromProfile(String languageCode) async {
    if (_isManuallySet) return; // 수동 설정 우선

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLocaleKey, languageCode);

    notifyListeners();
  }

  /// (옵션) 로그아웃 시 초기화하고 싶으면 사용
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefLocaleKey);
    await prefs.remove(_prefManualKey);

    _locale = null;
    _isManuallySet = false;
    notifyListeners();
  }
}
