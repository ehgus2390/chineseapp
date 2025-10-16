import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleState extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  /// 앱 시작 시 저장된 언어 복원 (기본: 시스템 언어)
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString('app_locale_code');
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    if (locale == null) {
      await sp.remove('app_locale_code'); // 시스템 기본으로
    } else {
      await sp.setString('app_locale_code', locale.languageCode);
    }
  }
}
