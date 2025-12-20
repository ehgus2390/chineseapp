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
  String get welcome => 'Welcome to Kkiri';

  @override
  String get startAnonymous => 'Start anonymously';

  @override
  String get emailLogin => 'Login with email';

  @override
  String get profile => 'Profile';

  @override
  String get friends => 'Friends';

  @override
  String get chat => 'Chat';

  @override
  String get map => 'Map';

  @override
  String get board => 'Board';

  @override
  String get settings => 'Settings';

  @override
  String get report => 'Report';

  @override
  String get block => 'Block';

  @override
  String get post => 'Post';

  @override
  String get comment => 'Comment';

  @override
  String get like => 'Like';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get save => 'Save';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get shareLocation => 'Share location';

  @override
  String get shareLocationDesc => 'Used for nearby friend recommendations';

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
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) => '$minutes min ago';

  @override
  String hoursAgo(int hours) => '$hours hours ago';

  @override
  String daysAgo(int days) => '$days days ago';

  @override
  String get homeCampusLabel => 'Campus';

  @override
  String get homeCampusFallback => 'Yonsei University';

  @override
  String get homeFeedEmpty => 'No posts yet. Share something to get started!';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryClasses => 'Classes';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryLifeInKorea => 'Life in Korea';

  @override
  String get writePostTitle => 'Write a post';

  @override
  String get writePostHint => 'Share what\'s happening on campus';

  @override
  String get cancel => 'Cancel';

  @override
  String get submitPost => 'Post';
}
