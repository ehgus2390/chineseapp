import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _map;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  Future<bool> load() async {
    final jsonStr = await rootBundle.loadString(
      'assets/i18n/intl_${locale.languageCode}.arb',
    );
    final Map<String, dynamic> data = json.decode(jsonStr);
    _map = data.map((k, v) => MapEntry(k, v.toString()));
    return true;
  }

  String t(String key) => _map[key] ?? key;

  // sugar getters
  String get appTitle => t('appTitle');
  String get tabDiscover => t('tabDiscover');
  String get tabChat => t('tabChat');
  String get tabProfile => t('tabProfile');
  String get discoverEmpty => t('discoverEmpty');
  String get like => t('like');
  String get pass => t('pass');
  String get languages => t('languages');
  String get country => t('country');
  String get bio => t('bio');
  String get startChat => t('startChat');
  String get yourLanguages => t('yourLanguages');
  String get preferences => t('preferences');
  String get prefTarget => t('prefTarget');
  String get save => t('save');
  String get chatEmpty => t('chatEmpty');
  String get discoverTitle => t('discoverTitle');
  String get profileTitle => t('profileTitle');
  String get name => t('name');
  String get age => t('age');
  String get occupation => t('occupation');
  String get interests => t('interests');
  String get gender => t('gender');
  String get male => t('male');
  String get female => t('female');
  String get distance => t('distance');
  String get distanceHint => t('distanceHint');
  String get location => t('location');
  String get latitude => t('latitude');
  String get longitude => t('longitude');
  String get appLanguage => t('appLanguage');
  String get preferredLanguages => t('preferredLanguages');
  String get onboardingTitle => t('onboardingTitle');
  String get cont => t('continue');
  String get nationality => t('nationality');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ko', 'en', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final l = AppLocalizations(locale);
    await l.load();
    return l;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
