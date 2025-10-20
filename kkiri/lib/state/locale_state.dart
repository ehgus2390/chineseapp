import 'package:flutter/material.dart';
import '../services/preferences_storage.dart';

class LocaleState extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;
  final PreferencesStorage _preferences = PreferencesStorage.instance;

  /// 앱 시작 시 저장된 언어 복원 (기본: 시스템 언어)
  Future<void> load() async {
    final code = await _preferences.readString('app_locale_code');
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _preferences.remove('app_locale_code'); // 시스템 기본으로
    } else {
      await _preferences.writeString('app_locale_code', locale.languageCode);
    }
  }
}
