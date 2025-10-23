import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ko');
  Locale get locale => _locale;

  void setLocale(Locale loc) {
    _locale = loc;
    notifyListeners();
  }
}
