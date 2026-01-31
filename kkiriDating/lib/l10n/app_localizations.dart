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
  String get languageNameKorean => t('languageNameKorean');
  String get languageNameJapanese => t('languageNameJapanese');
  String get languageNameEnglish => t('languageNameEnglish');
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
  String get refreshRecommendations => t('refreshRecommendations');
  String get distanceNear => t('distanceNear');
  String get distanceMedium => t('distanceMedium');
  String get distanceFar => t('distanceFar');
  String get distanceNoLimit => t('distanceNoLimit');
  String get distanceRangeLabel => t('distanceRangeLabel');
  String get locationSet => t('locationSet');
  String get locationUnset => t('locationUnset');
  String get notificationsTitle => t('notificationsTitle');
  String get notificationsSubtitle => t('notificationsSubtitle');
  String get queueSearchingTitle => t('queueSearchingTitle');
  String get queueSearchingSubtitle => t('queueSearchingSubtitle');
  String get queueSearchStepDistance => t('queueSearchStepDistance');
  String get queueSearchStepInterests => t('queueSearchStepInterests');
  String get queueSearchStepExplore => t('queueSearchStepExplore');
  String get queueSearchStepAnalysis => t('queueSearchStepAnalysis');
  String get queueSearchTipPhoto => t('queueSearchTipPhoto');
  String get queueSearchTipBio => t('queueSearchTipBio');
  String get queueSearchTipNewUsers => t('queueSearchTipNewUsers');
  String get queueTimeout => t('queueTimeout');
  String get queueConnect => t('queueConnect');
  String get queueAccept => t('queueAccept');
  String get queueDecline => t('queueDecline');
  String get queueStop => t('queueStop');
  String queueRemainingTime(String seconds) =>
      t('queueRemainingTime').replaceAll('{seconds}', seconds);
  String get queueResumeSubtitle => t('queueResumeSubtitle');
  String get notificationMatchAcceptedToast =>
      t('notificationMatchAcceptedToast');
  String get notificationNewMessageToast => t('notificationNewMessageToast');
  String get notificationViewAction => t('notificationViewAction');
  String get likesInboxTitle => t('likesInboxTitle');
  String get likesInboxEmpty => t('likesInboxEmpty');
  String get notificationsInboxTitle => t('notificationsInboxTitle');
  String get notificationsInboxEmpty => t('notificationsInboxEmpty');
  String get notificationsLikeText => t('notificationsLikeText');
  String get notificationsMatchText => t('notificationsMatchText');
  String get notificationsChatText => t('notificationsChatText');
  String get notificationsSystemText => t('notificationsSystemText');
  String get profileSaved => t('profileSaved');
  String get retry => t('retry');
  String get matchFoundTitle => t('matchFoundTitle');
  String profileNameAge(String name, String age) =>
      t('profileNameAge').replaceAll('{name}', name).replaceAll('{age}', age);
  String profileNameAgeCountry(String name, String age, String country) =>
      t('profileNameAgeCountry')
          .replaceAll('{name}', name)
          .replaceAll('{age}', age)
          .replaceAll('{country}', country);

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
  String get chatExit => t('chatExit');

  String get profileCompletionTitle => t('profileCompletionTitle');
  String profileCompletionProgress(String percent) =>
      t('profileCompletionProgress').replaceAll('{percent}', percent);
  String get profileCompletionPhoto => t('profileCompletionPhoto');
  String get profileCompletionBio => t('profileCompletionBio');
  String get profileCompletionBasicInfo => t('profileCompletionBasicInfo');
  String get profileCompletionCta => t('profileCompletionCta');
  String get profileBioPlaceholder => t('profileBioPlaceholder');
  String get profileBioPlaceholderAlt => t('profileBioPlaceholderAlt');

  String get authVerifyIntro => t('authVerifyIntro');
  String get authVerifyPhoneButton => t('authVerifyPhoneButton');
  String get authVerifyEmailButton => t('authVerifyEmailButton');
  String get authPhoneLabel => t('authPhoneLabel');
  String get authSendCode => t('authSendCode');
  String get authCodeLabel => t('authCodeLabel');
  String get authVerifyCompleteButton => t('authVerifyCompleteButton');
  String get authSendEmailVerification => t('authSendEmailVerification');
  String get authCheckEmailVerified => t('authCheckEmailVerified');

  String get authErrorInvalidEmail => t('authErrorInvalidEmail');
  String get authErrorEmailInUse => t('authErrorEmailInUse');
  String get authErrorWrongPassword => t('authErrorWrongPassword');
  String get authErrorUserNotFound => t('authErrorUserNotFound');
  String get authErrorTooManyRequests => t('authErrorTooManyRequests');
  String get authErrorInvalidVerificationCode =>
      t('authErrorInvalidVerificationCode');
  String get authErrorInvalidVerificationId =>
      t('authErrorInvalidVerificationId');
  String get authErrorVerificationFailed => t('authErrorVerificationFailed');
  String get authErrorVerificationRequired =>
      t('authErrorVerificationRequired');
  String get authErrorEmptyEmailPassword => t('authErrorEmptyEmailPassword');
  String get authErrorPhoneEmpty => t('authErrorPhoneEmpty');
  String get authErrorCodeEmpty => t('authErrorCodeEmpty');
  String get authErrorGeneric => t('authErrorGeneric');

  String get uploadErrorPermission => t('uploadErrorPermission');
  String get uploadErrorCanceled => t('uploadErrorCanceled');
  String get uploadErrorUnauthorized => t('uploadErrorUnauthorized');
  String get uploadErrorNetwork => t('uploadErrorNetwork');
  String get uploadErrorUnknown => t('uploadErrorUnknown');
  String get uploadErrorFailed => t('uploadErrorFailed');
  String get uploadErrorFileRead => t('uploadErrorFileRead');
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
