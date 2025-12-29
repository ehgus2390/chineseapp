// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kkiri';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get friends => 'Friends';

  @override
  String get chat => 'Chat';

  @override
  String get map => 'Map';

  @override
  String get board => 'Community';

  @override
  String get settings => 'Settings';

  @override
  String get welcome => 'Welcome to Kkiri';

  @override
  String get welcomeSubtitle => 'Your first friend in Korea starts here';

  @override
  String get findMyPeople => 'Find my people';

  @override
  String get peopleNearYou => 'People near you';

  @override
  String get seeMore => 'See more';

  @override
  String get myCommunities => 'My communities';

  @override
  String get manage => 'Manage';

  @override
  String get smallEvents => 'Small events';

  @override
  String get smallEventsSubtitle => 'Meet people naturally, not crowded.';

  @override
  String get sayHi => 'Say hi';

  @override
  String get sendRequest => 'Send message request';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get displayName => 'Display name';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get bio => 'Bio';

  @override
  String get save => 'Save';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get report => 'Report';

  @override
  String get block => 'Block';

  @override
  String get reportDescription => 'Report posts, comments, or users.';

  @override
  String get blockDescription =>
      'Blocked users\' posts and chats will be hidden.';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get universityCommunityTitle => 'University community';

  @override
  String get universityCommunitySubtitle => 'Only for your campus';

  @override
  String get universityCommunityEmpty =>
      'No posts yet in your campus community.';

  @override
  String get universityCommunityMissing =>
      'We couldn\'t find your university community.';

  @override
  String get homeCampusLabel => 'Campus';

  @override
  String get homeCampusFallback => 'Please set your campus';

  @override
  String get homeFeedEmpty => 'No posts in your feed yet.';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryClasses => 'Classes';

  @override
  String get shareLocation => 'Share location';

  @override
  String get shareLocationDesc => 'Share your location.';

  @override
  String get logout => 'Logout';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryLifeInKorea => 'Life in Korea';

  @override
  String get writePostTitle => 'Write a post';

  @override
  String get writePostHint => 'Share what\'s happening on your campus';

  @override
  String get cancel => 'Cancel';

  @override
  String get submitPost => 'Submit Post';

  @override
  String get post => 'Post';

  @override
  String get comment => 'Comment';

  @override
  String get like => 'Like';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String daysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get login => 'Login';

  @override
  String get requireEmailLoginTitle => 'Email login required';

  @override
  String requireEmailLoginMessage(Object featureName) {
    return 'To use $featureName, please log in with email.';
  }

  @override
  String get loginAction => 'Login';

  @override
  String get profileLoginRequiredMessage =>
      'This feature is available after login.';

  @override
  String get chatLoginRequiredMessage => 'Login is required to use chat.';
}
