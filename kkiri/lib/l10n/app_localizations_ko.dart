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
  String get home => '홈';

  @override
  String get profile => '프로필';

  @override
  String get friends => '친구';

  @override
  String get chat => '채팅';

  @override
  String get map => '지도';

  @override
  String get board => '커뮤니티';

  @override
  String get settings => '설정';

  @override
  String get welcome => '끼리에 오신 것을 환영합니다';

  @override
  String get welcomeSubtitle => '한국에서의 첫 친구를 여기서 만나보세요';

  @override
  String get findMyPeople => '내 사람 찾기';

  @override
  String get peopleNearYou => '내 주변 사람들';

  @override
  String get seeMore => '더 보기';

  @override
  String get myCommunities => '내 커뮤니티';

  @override
  String get manage => '관리';

  @override
  String get smallEvents => '소규모 모임';

  @override
  String get smallEventsSubtitle => '붐비지 않게, 자연스럽게 만나요.';

  @override
  String get sayHi => '인사하기';

  @override
  String get sendRequest => '메시지 요청 보내기';

  @override
  String get profileSaved => '프로필이 저장되었습니다';

  @override
  String get changePhoto => '사진 변경';

  @override
  String get displayName => '닉네임';

  @override
  String get age => '나이';

  @override
  String get gender => '성별';

  @override
  String get bio => '자기소개';

  @override
  String get save => '저장';

  @override
  String get genderMale => '남성';

  @override
  String get genderFemale => '여성';

  @override
  String get genderOther => '기타';

  @override
  String get language => '언어';

  @override
  String get languageEnglish => '영어';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageJapanese => '일본어';

  @override
  String get languageChinese => '중국어';

  @override
  String get report => '신고';

  @override
  String get block => '차단';

  @override
  String get reportDescription => '게시글, 댓글 또는 사용자를 신고할 수 있습니다.';

  @override
  String get blockDescription => '차단한 사용자의 게시글과 채팅은 보이지 않습니다.';

  @override
  String get anonymous => '익명';

  @override
  String get universityCommunityTitle => '대학교 커뮤니티';

  @override
  String get universityCommunitySubtitle => '내 캠퍼스 전용';

  @override
  String get universityCommunityEmpty => '캠퍼스 커뮤니티에 아직 게시글이 없습니다.';

  @override
  String get universityCommunityMissing => '대학교 커뮤니티를 찾지 못했습니다.';

  @override
  String get homeCampusLabel => '캠퍼스';

  @override
  String get homeCampusFallback => '캠퍼스를 설정해주세요';

  @override
  String get homeFeedEmpty => '캠퍼스에 새로운 소식이 없습니다.';

  @override
  String get categoryFood => '음식';

  @override
  String get categoryClasses => '수업';

  @override
  String get shareLocation => 'Share location';

  @override
  String get shareLocationDesc => 'Share your location.';

  @override
  String get logout => 'Logout';

  @override
  String get categoryHousing => '주거';

  @override
  String get categoryLifeInKorea => '한국 생활';

  @override
  String get writePostTitle => '게시글 작성';

  @override
  String get writePostHint => '게시글을 입력하세요';

  @override
  String get cancel => '취소';

  @override
  String get submitPost => '게시글 등록';

  @override
  String get post => '게시글';

  @override
  String get comment => '댓글';

  @override
  String get like => '좋아요';

  @override
  String get justNow => '방금 전';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes분 전';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours시간 전';
  }

  @override
  String daysAgo(Object days) {
    return '$days일 전';
  }
}
