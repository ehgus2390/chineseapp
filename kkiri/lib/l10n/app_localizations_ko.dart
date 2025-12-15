// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '끼리';

  @override
  String get welcome => 'Kkiri에 오신 것을 환영합니다';

  @override
  String get startAnonymous => '익명으로 시작하기';

  @override
  String get emailLogin => '이메일로 로그인';

  @override
  String get profile => '프로필';

  @override
  String get settings => '설정';

  @override
  String get report => '신고하기';

  @override
  String get block => '차단하기';

  @override
  String get post => '게시글';

  @override
  String get comment => '댓글';

  @override
  String get like => '좋아요';

  @override
  String get anonymous => '익명';

  @override
  String get save => '저장';

  @override
  String get logout => '로그아웃';

  @override
  String get language => '언어';
}
