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
  String get tabRecommend => t('tabRecommend');
  String get tabNearby => t('tabNearby');
  String get tabFeed => t('tabFeed');
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
  String get chatTitle => t('chatTitle');
  String get chatFilterAll => t('chatFilterAll');
  String get chatFilterLikes => t('chatFilterLikes');
  String get chatFilterNew => t('chatFilterNew');
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
  String get useCurrentLocation => t('useCurrentLocation');
  String get locationUpdated => t('locationUpdated');
  String get locationServiceOff => t('locationServiceOff');
  String get locationPermissionDenied => t('locationPermissionDenied');
  String get appLanguage => t('appLanguage');
  String get preferredLanguages => t('preferredLanguages');
  String get onboardingTitle => t('onboardingTitle');
  String get cont => t('continue');
  String get loginTitle => t('loginTitle');
  String get loginSubtitle => t('loginSubtitle');
  String get email => t('email');
  String get password => t('password');
  String get signIn => t('signIn');
  String get signUp => t('signUp');
  String get needAccount => t('needAccount');
  String get haveAccount => t('haveAccount');
  String get signOut => t('signOut');

  String get matchingSearchingTitle => t('matchingSearchingTitle');
  String get matchingSearchingSubtitle => t('matchingSearchingSubtitle');
  String get recommendCardSubtitle => t('recommendCardSubtitle');
  String get noMatchTitle => t('noMatchTitle');
  String get noMatchSubtitle => t('noMatchSubtitle');
  String get noMatchAction => t('noMatchAction');
  String get profileCompleteTitle => t('profileCompleteTitle');
  String get profileCompleteAction => t('profileCompleteAction');
  String get chatSearchingTitle => t('chatSearchingTitle');
  String get chatSearchingEmoji => t('chatSearchingEmoji');
  String get chatSearchingSubtitle => t('chatSearchingSubtitle');
  String get chatMatchTitle => t('chatMatchTitle');
  String get chatMatchSubtitle => t('chatMatchSubtitle');
  String get chatStartButton => t('chatStartButton');
  String get chatWaitingTitle => t('chatWaitingTitle');
  String get chatWaitingSubtitle => t('chatWaitingSubtitle');
  String get matchingConsentTitle => t('matchingConsentTitle');
  String get matchingConsentSubtitle => t('matchingConsentSubtitle');
  String get matchingConnectButton => t('matchingConnectButton');
  String get matchingSkipButton => t('matchingSkipButton');
  String get waitingForOtherUser => t('waitingForOtherUser');
  String get firstMessageGuide => t('firstMessageGuide');
  String get firstMessageSuggestions => t('firstMessageSuggestions');
  String get chatInputHint => t('chatInputHint');
  String get chatError => t('chatError');
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
