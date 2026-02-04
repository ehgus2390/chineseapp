import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kkiri Dating'**
  String get appTitle;

  /// No description provided for @tabRecommend.
  ///
  /// In en, this message translates to:
  /// **'Recommend'**
  String get tabRecommend;

  /// No description provided for @tabNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get tabNearby;

  /// No description provided for @tabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get tabFeed;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommend'**
  String get discoverTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @discoverEmpty.
  ///
  /// In en, this message translates to:
  /// **'No eligible profiles available'**
  String get discoverEmpty;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching friends yet'**
  String get chatEmpty;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatFilterAll;

  /// No description provided for @chatFilterLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get chatFilterLikes;

  /// No description provided for @chatFilterNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get chatFilterNew;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start chat'**
  String get startChat;

  /// No description provided for @yourLanguages.
  ///
  /// In en, this message translates to:
  /// **'Your languages'**
  String get yourLanguages;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @preferredLanguages.
  ///
  /// In en, this message translates to:
  /// **'Preferred languages'**
  String get preferredLanguages;

  /// No description provided for @prefTarget.
  ///
  /// In en, this message translates to:
  /// **'Languages for recommendations'**
  String get prefTarget;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @distanceHint.
  ///
  /// In en, this message translates to:
  /// **'Distance range'**
  String get distanceHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get locationUpdated;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services'**
  String get locationServiceOff;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionDenied;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @languageNameKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageNameKorean;

  /// No description provided for @languageNameJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageNameJapanese;

  /// No description provided for @languageNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingTitle;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get needAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @refreshRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Get new recommendations'**
  String get refreshRecommendations;

  /// No description provided for @distanceNear.
  ///
  /// In en, this message translates to:
  /// **'Near'**
  String get distanceNear;

  /// No description provided for @distanceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get distanceMedium;

  /// No description provided for @distanceFar.
  ///
  /// In en, this message translates to:
  /// **'Far'**
  String get distanceFar;

  /// No description provided for @distanceNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No distance limit'**
  String get distanceNoLimit;

  /// No description provided for @distanceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance range'**
  String get distanceRangeLabel;

  /// No description provided for @locationSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get locationSet;

  /// No description provided for @locationUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get locationUnset;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive match and message alerts'**
  String get notificationsSubtitle;

  /// No description provided for @queueSearchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Matching you with someone'**
  String get queueSearchingTitle;

  /// No description provided for @queueSearchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Looking for the other person. Please wait.'**
  String get queueSearchingSubtitle;

  /// No description provided for @queueSearchStepDistance.
  ///
  /// In en, this message translates to:
  /// **'Checking distance...'**
  String get queueSearchStepDistance;

  /// No description provided for @queueSearchStepInterests.
  ///
  /// In en, this message translates to:
  /// **'Comparing interests...'**
  String get queueSearchStepInterests;

  /// No description provided for @queueSearchStepExplore.
  ///
  /// In en, this message translates to:
  /// **'Searching for someone...'**
  String get queueSearchStepExplore;

  /// No description provided for @queueSearchStepAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analyzing match potential...'**
  String get queueSearchStepAnalysis;

  /// No description provided for @queueSearchTipPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos boost response rates'**
  String get queueSearchTipPhoto;

  /// No description provided for @queueSearchTipBio.
  ///
  /// In en, this message translates to:
  /// **'A good bio speeds up matching'**
  String get queueSearchTipBio;

  /// No description provided for @queueSearchTipNewUsers.
  ///
  /// In en, this message translates to:
  /// **'New people are joining right now'**
  String get queueSearchTipNewUsers;

  /// No description provided for @queueTimeout.
  ///
  /// In en, this message translates to:
  /// **'Response timed out'**
  String get queueTimeout;

  /// No description provided for @queueConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get queueConnect;

  /// No description provided for @queueAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get queueAccept;

  /// No description provided for @queueDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get queueDecline;

  /// No description provided for @queueStop.
  ///
  /// In en, this message translates to:
  /// **'Stop matching'**
  String get queueStop;

  /// No description provided for @queueRemainingTime.
  ///
  /// In en, this message translates to:
  /// **'Time left {seconds}s'**
  String queueRemainingTime(Object seconds);

  /// No description provided for @queueResumeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Looking for another match ?뙮'**
  String get queueResumeSubtitle;

  /// No description provided for @notificationMatchAcceptedToast.
  ///
  /// In en, this message translates to:
  /// **'?뮒 Match complete. Start chatting now.'**
  String get notificationMatchAcceptedToast;

  /// No description provided for @notificationNewMessageToast.
  ///
  /// In en, this message translates to:
  /// **'?뮠 New message received'**
  String get notificationNewMessageToast;

  /// No description provided for @notificationViewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get notificationViewAction;

  /// No description provided for @likesInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get likesInboxTitle;

  /// No description provided for @likesInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new notifications ?뭽'**
  String get likesInboxEmpty;

  /// No description provided for @notificationsInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsInboxTitle;

  /// No description provided for @notificationsInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new notifications ?뭽'**
  String get notificationsInboxEmpty;

  /// No description provided for @notificationsLikeText.
  ///
  /// In en, this message translates to:
  /// **'{name} liked your profile'**
  String notificationsLikeText(Object name);

  /// No description provided for @notificationsMatchText.
  ///
  /// In en, this message translates to:
  /// **'You have a new match'**
  String get notificationsMatchText;

  /// No description provided for @notificationsChatText.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notificationsChatText;

  /// No description provided for @notificationsSystemText.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationsSystemText;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @matchFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'MATCH FOUND!'**
  String get matchFoundTitle;

  /// No description provided for @profileNameAge.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age}'**
  String profileNameAge(Object age, Object name);

  /// No description provided for @profileNameAgeCountry.
  ///
  /// In en, this message translates to:
  /// **'{name}, {age} 쨌 {country}'**
  String profileNameAgeCountry(Object age, Object country, Object name);

  /// No description provided for @matchingSearchingTitle.
  ///
  /// In en, this message translates to:
  /// **'?뮉 Finding someone new'**
  String get matchingSearchingTitle;

  /// No description provided for @matchingSearchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment'**
  String get matchingSearchingSubtitle;

  /// No description provided for @recommendCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'??You might really click on interests'**
  String get recommendCardSubtitle;

  /// No description provided for @noMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'?뮡 We haven\'t found a perfect match yet'**
  String get noMatchTitle;

  /// No description provided for @noMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your interests or distance'**
  String get noMatchSubtitle;

  /// No description provided for @noMatchAction.
  ///
  /// In en, this message translates to:
  /// **'Edit interests'**
  String get noMatchAction;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get recommendations'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get profileCompleteAction;

  /// No description provided for @chatSearchingEmoji.
  ///
  /// In en, this message translates to:
  /// **'?뮉'**
  String get chatSearchingEmoji;

  /// No description provided for @chatSearchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding a friend that fits you'**
  String get chatSearchingTitle;

  /// No description provided for @chatSearchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prioritizing people with similar interests'**
  String get chatSearchingSubtitle;

  /// No description provided for @chatMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'?뮠 Want to start a chat?'**
  String get chatMatchTitle;

  /// No description provided for @chatMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Someone is here to talk right now'**
  String get chatMatchSubtitle;

  /// No description provided for @chatStartButton.
  ///
  /// In en, this message translates to:
  /// **'?뮉 Start chatting now'**
  String get chatStartButton;

  /// No description provided for @chatWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'?뙮 Still connecting'**
  String get chatWaitingTitle;

  /// No description provided for @chatWaitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait a little longer'**
  String get chatWaitingSubtitle;

  /// No description provided for @matchingConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'?뮠 Want to start a chat now?'**
  String get matchingConsentTitle;

  /// No description provided for @matchingConsentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Someone is here to talk right now'**
  String get matchingConsentSubtitle;

  /// No description provided for @matchingConnectButton.
  ///
  /// In en, this message translates to:
  /// **'?뮉 Connect'**
  String get matchingConnectButton;

  /// No description provided for @matchingSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Wait for the next match'**
  String get matchingSkipButton;

  /// No description provided for @waitingForOtherUser.
  ///
  /// In en, this message translates to:
  /// **'Waiting for their response'**
  String get waitingForOtherUser;

  /// No description provided for @firstMessageGuide.
  ///
  /// In en, this message translates to:
  /// **'??Start the conversation!\nIt helps to begin with a shared interest.'**
  String get firstMessageGuide;

  /// No description provided for @firstMessageSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Do you do {interest} often these days?|What got you into {interest}?|Are you into anything besides {interest}?'**
  String firstMessageSuggestions(Object interest);

  /// No description provided for @firstMessageSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Do you do {interest} often these days?'**
  String firstMessageSuggestion1(Object interest);

  /// No description provided for @firstMessageSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'What got you into {interest}?'**
  String firstMessageSuggestion2(Object interest);

  /// No description provided for @firstMessageSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Are you into anything besides {interest}?'**
  String firstMessageSuggestion3(Object interest);

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatInputHint;

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get chatError;

  /// No description provided for @chatExit.
  ///
  /// In en, this message translates to:
  /// **'Exit chat'**
  String get chatExit;

  /// No description provided for @profileCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile completion'**
  String get profileCompletionTitle;

  /// No description provided for @profileCompletionProgress.
  ///
  /// In en, this message translates to:
  /// **'Profile completion {percent}%'**
  String profileCompletionProgress(Object percent);

  /// No description provided for @profileCompletionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo'**
  String get profileCompletionPhoto;

  /// No description provided for @profileCompletionBio.
  ///
  /// In en, this message translates to:
  /// **'Write your bio'**
  String get profileCompletionBio;

  /// No description provided for @profileCompletionBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Fill in basic info'**
  String get profileCompletionBasicInfo;

  /// No description provided for @profileCompletionCta.
  ///
  /// In en, this message translates to:
  /// **'Start matching'**
  String get profileCompletionCta;

  /// No description provided for @profileBioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get profileBioPlaceholder;

  /// No description provided for @profileBioPlaceholderAlt.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get profileBioPlaceholderAlt;

  /// No description provided for @authVerifyIntro.
  ///
  /// In en, this message translates to:
  /// **'Verification is required for a safe sign-up'**
  String get authVerifyIntro;

  /// No description provided for @authVerifyPhoneButton.
  ///
  /// In en, this message translates to:
  /// **'Phone verification'**
  String get authVerifyPhoneButton;

  /// No description provided for @authVerifyEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get authVerifyEmailButton;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneLabel;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get authCodeLabel;

  /// No description provided for @authVerifyCompleteButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerifyCompleteButton;

  /// No description provided for @authSendEmailVerification.
  ///
  /// In en, this message translates to:
  /// **'Send verification email'**
  String get authSendEmailVerification;

  /// No description provided for @authCheckEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get authCheckEmailVerified;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorInvalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Incorrect verification code.'**
  String get authErrorInvalidVerificationCode;

  /// No description provided for @authErrorInvalidVerificationId.
  ///
  /// In en, this message translates to:
  /// **'Verification session expired. Please try again.'**
  String get authErrorInvalidVerificationId;

  /// No description provided for @authErrorVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again shortly.'**
  String get authErrorVerificationFailed;

  /// No description provided for @authErrorVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Complete verification to sign up.'**
  String get authErrorVerificationRequired;

  /// No description provided for @authErrorEmptyEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password.'**
  String get authErrorEmptyEmailPassword;

  /// No description provided for @authErrorPhoneEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number.'**
  String get authErrorPhoneEmpty;

  /// No description provided for @authErrorCodeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code.'**
  String get authErrorCodeEmpty;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete the request. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @uploadErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Photo permission is required. Please allow access in settings.'**
  String get uploadErrorPermission;

  /// No description provided for @uploadErrorCanceled.
  ///
  /// In en, this message translates to:
  /// **'Upload was canceled. Please try again.'**
  String get uploadErrorCanceled;

  /// No description provided for @uploadErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get uploadErrorUnauthorized;

  /// No description provided for @uploadErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network is unstable. Please try again soon.'**
  String get uploadErrorNetwork;

  /// No description provided for @uploadErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred. Please try again.'**
  String get uploadErrorUnknown;

  /// No description provided for @uploadErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get uploadErrorFailed;

  /// No description provided for @uploadErrorFileRead.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read that photo. Please choose another.'**
  String get uploadErrorFileRead;

  /// No description provided for @reportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportConfirm;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or ads'**
  String get reportReasonSpam;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a reason to report'**
  String get reportTitle;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abusive behavior'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportCancel;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your report has been submitted'**
  String get reportSubmitted;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
