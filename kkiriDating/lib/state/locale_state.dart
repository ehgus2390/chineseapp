import 'package:flutter/material.dart';
import '../services/preferences_storage.dart';

class LocaleState extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;
  final PreferencesStorage _preferences = PreferencesStorage.instance;

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
      await _preferences.remove('app_locale_code');
    } else {
      await _preferences.writeString('app_locale_code', locale.languageCode);
    }
  }
}
