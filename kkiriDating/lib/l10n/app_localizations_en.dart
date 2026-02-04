// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kkiri Dating';

  @override
  String get tabRecommend => 'Recommend';

  @override
  String get tabNearby => 'Nearby';

  @override
  String get tabFeed => 'Feed';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabProfile => 'Profile';

  @override
  String get discoverTitle => 'Recommend';

  @override
  String get profileTitle => 'Profile';

  @override
  String get discoverEmpty => 'No eligible profiles available';

  @override
  String get chatEmpty => 'No matching friends yet';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatFilterAll => 'All';

  @override
  String get chatFilterLikes => 'Likes';

  @override
  String get chatFilterNew => 'NEW';

  @override
  String get like => 'Like';

  @override
  String get pass => 'Pass';

  @override
  String get languages => 'Languages';

  @override
  String get country => 'Country';

  @override
  String get bio => 'Bio';

  @override
  String get startChat => 'Start chat';

  @override
  String get yourLanguages => 'Your languages';

  @override
  String get preferences => 'Preferences';

  @override
  String get preferredLanguages => 'Preferred languages';

  @override
  String get prefTarget => 'Languages for recommendations';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String get age => 'Age';

  @override
  String get occupation => 'Occupation';

  @override
  String get interests => 'Interests';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get distance => 'Distance';

  @override
  String get distanceHint => 'Distance range';

  @override
  String get location => 'Location';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get locationUpdated => 'Location updated';

  @override
  String get locationServiceOff => 'Please enable location services';

  @override
  String get locationPermissionDenied => 'Location permission is required';

  @override
  String get appLanguage => 'App language';

  @override
  String get languageNameKorean => 'Korean';

  @override
  String get languageNameJapanese => 'Japanese';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get onboardingTitle => 'Welcome';

  @override
  String get continueAction => 'Continue';

  @override
  String get loginTitle => 'Welcome';

  @override
  String get loginSubtitle => 'Sign in with email';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get needAccount => 'Create an account';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get signOut => 'Sign out';

  @override
  String get refreshRecommendations => 'Get new recommendations';

  @override
  String get distanceNear => 'Near';

  @override
  String get distanceMedium => 'Medium';

  @override
  String get distanceFar => 'Far';

  @override
  String get distanceNoLimit => 'No distance limit';

  @override
  String get distanceRangeLabel => 'Distance range';

  @override
  String get locationSet => 'Set';

  @override
  String get locationUnset => 'Not set';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle => 'Receive match and message alerts';

  @override
  String get queueSearchingTitle => 'Matching you with someone';

  @override
  String get queueSearchingSubtitle =>
      'Looking for the other person. Please wait.';

  @override
  String get queueSearchStepDistance => 'Checking distance...';

  @override
  String get queueSearchStepInterests => 'Comparing interests...';

  @override
  String get queueSearchStepExplore => 'Searching for someone...';

  @override
  String get queueSearchStepAnalysis => 'Analyzing match potential...';

  @override
  String get queueSearchTipPhoto => 'Photos boost response rates';

  @override
  String get queueSearchTipBio => 'A good bio speeds up matching';

  @override
  String get queueSearchTipNewUsers => 'New people are joining right now';

  @override
  String get queueTimeout => 'Response timed out';

  @override
  String get queueConnect => 'Connect';

  @override
  String get queueAccept => 'Accept';

  @override
  String get queueDecline => 'Decline';

  @override
  String get queueStop => 'Stop matching';

  @override
  String queueRemainingTime(Object seconds) {
    return 'Time left ${seconds}s';
  }

  @override
  String get queueResumeSubtitle => 'Looking for another match ?뙮';

  @override
  String get notificationMatchAcceptedToast =>
      '?뮒 Match complete. Start chatting now.';

  @override
  String get notificationNewMessageToast => '?뮠 New message received';

  @override
  String get notificationViewAction => 'View';

  @override
  String get likesInboxTitle => 'Notifications';

  @override
  String get likesInboxEmpty => 'No new notifications ?뭽';

  @override
  String get notificationsInboxTitle => 'Notifications';

  @override
  String get notificationsInboxEmpty => 'No new notifications ?뭽';

  @override
  String notificationsLikeText(Object name) {
    return '$name liked your profile';
  }

  @override
  String get notificationsMatchText => 'You have a new match';

  @override
  String get notificationsChatText => 'New message';

  @override
  String get notificationsSystemText => 'Notification';

  @override
  String get profileSaved => 'Saved';

  @override
  String get retry => 'Retry';

  @override
  String get matchFoundTitle => 'MATCH FOUND!';

  @override
  String profileNameAge(Object age, Object name) {
    return '$name, $age';
  }

  @override
  String profileNameAgeCountry(Object age, Object country, Object name) {
    return '$name, $age 쨌 $country';
  }

  @override
  String get matchingSearchingTitle => '?뮉 Finding someone new';

  @override
  String get matchingSearchingSubtitle => 'Please wait a moment';

  @override
  String get recommendCardSubtitle => '??You might really click on interests';

  @override
  String get noMatchTitle => '?뮡 We haven\'t found a perfect match yet';

  @override
  String get noMatchSubtitle => 'Try adjusting your interests or distance';

  @override
  String get noMatchAction => 'Edit interests';

  @override
  String get profileCompleteTitle =>
      'Complete your profile to get recommendations';

  @override
  String get profileCompleteAction => 'Complete profile';

  @override
  String get chatSearchingEmoji => '?뮉';

  @override
  String get chatSearchingTitle => 'Finding a friend that fits you';

  @override
  String get chatSearchingSubtitle =>
      'Prioritizing people with similar interests';

  @override
  String get chatMatchTitle => '?뮠 Want to start a chat?';

  @override
  String get chatMatchSubtitle => 'Someone is here to talk right now';

  @override
  String get chatStartButton => '?뮉 Start chatting now';

  @override
  String get chatWaitingTitle => '?뙮 Still connecting';

  @override
  String get chatWaitingSubtitle => 'Please wait a little longer';

  @override
  String get matchingConsentTitle => '?뮠 Want to start a chat now?';

  @override
  String get matchingConsentSubtitle => 'Someone is here to talk right now';

  @override
  String get matchingConnectButton => '?뮉 Connect';

  @override
  String get matchingSkipButton => 'Wait for the next match';

  @override
  String get waitingForOtherUser => 'Waiting for their response';

  @override
  String get firstMessageGuide =>
      '??Start the conversation!\nIt helps to begin with a shared interest.';

  @override
  String firstMessageSuggestions(Object interest) {
    return 'Do you do $interest often these days?|What got you into $interest?|Are you into anything besides $interest?';
  }

  @override
  String firstMessageSuggestion1(Object interest) {
    return 'Do you do $interest often these days?';
  }

  @override
  String firstMessageSuggestion2(Object interest) {
    return 'What got you into $interest?';
  }

  @override
  String firstMessageSuggestion3(Object interest) {
    return 'Are you into anything besides $interest?';
  }

  @override
  String get chatInputHint => 'Type a message';

  @override
  String get chatError => 'Something went wrong';

  @override
  String get chatExit => 'Exit chat';

  @override
  String get profileCompletionTitle => 'Profile completion';

  @override
  String profileCompletionProgress(Object percent) {
    return 'Profile completion $percent%';
  }

  @override
  String get profileCompletionPhoto => 'Add a profile photo';

  @override
  String get profileCompletionBio => 'Write your bio';

  @override
  String get profileCompletionBasicInfo => 'Fill in basic info';

  @override
  String get profileCompletionCta => 'Start matching';

  @override
  String get profileBioPlaceholder => 'Hello';

  @override
  String get profileBioPlaceholderAlt => 'Hello!';

  @override
  String get authVerifyIntro => 'Verification is required for a safe sign-up';

  @override
  String get authVerifyPhoneButton => 'Phone verification';

  @override
  String get authVerifyEmailButton => 'Email verification';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authCodeLabel => 'Enter verification code';

  @override
  String get authVerifyCompleteButton => 'Verify';

  @override
  String get authSendEmailVerification => 'Send verification email';

  @override
  String get authCheckEmailVerified => 'I\'ve verified my email';

  @override
  String get authErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authErrorEmailInUse => 'This email is already in use.';

  @override
  String get authErrorWrongPassword => 'Incorrect password.';

  @override
  String get authErrorUserNotFound => 'No account found for this email.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authErrorInvalidVerificationCode => 'Incorrect verification code.';

  @override
  String get authErrorInvalidVerificationId =>
      'Verification session expired. Please try again.';

  @override
  String get authErrorVerificationFailed =>
      'Verification failed. Please try again shortly.';

  @override
  String get authErrorVerificationRequired =>
      'Complete verification to sign up.';

  @override
  String get authErrorEmptyEmailPassword => 'Please enter email and password.';

  @override
  String get authErrorPhoneEmpty => 'Please enter your phone number.';

  @override
  String get authErrorCodeEmpty => 'Please enter the verification code.';

  @override
  String get authErrorGeneric =>
      'We couldn\'t complete the request. Please try again.';

  @override
  String get uploadErrorPermission =>
      'Photo permission is required. Please allow access in settings.';

  @override
  String get uploadErrorCanceled => 'Upload was canceled. Please try again.';

  @override
  String get uploadErrorUnauthorized =>
      'Your session expired. Please sign in again.';

  @override
  String get uploadErrorNetwork =>
      'Network is unstable. Please try again soon.';

  @override
  String get uploadErrorUnknown =>
      'An unknown error occurred. Please try again.';

  @override
  String get uploadErrorFailed => 'Upload failed. Please try again.';

  @override
  String get uploadErrorFileRead =>
      'We couldn\'t read that photo. Please choose another.';

  @override
  String get reportConfirm => 'Report';

  @override
  String get reportReasonSpam => 'Spam or ads';

  @override
  String get reportAction => 'Report';

  @override
  String get reportTitle => 'Select a reason to report';

  @override
  String get reportReasonHarassment => 'Harassment or abusive behavior';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportCancel => 'Cancel';

  @override
  String get reportSubmitted => 'Your report has been submitted';

  @override
  String get reportReasonOther => 'Other';
}
