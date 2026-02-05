// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '끼리 데이팅';

  @override
  String get tabRecommend => '추천';

  @override
  String get tabNearby => '근처';

  @override
  String get tabFeed => '피드';

  @override
  String get tabChat => '채팅';

  @override
  String get tabProfile => '프로필';

  @override
  String get discoverTitle => '추천';

  @override
  String get profileTitle => '프로필';

  @override
  String get discoverEmpty => '조건에 맞는 프로필이 없습니다';

  @override
  String get chatEmpty => '조건에 맞는 친구가 없어요';

  @override
  String get chatTitle => '채팅';

  @override
  String get chatFilterAll => '전체';

  @override
  String get chatFilterLikes => '좋아요';

  @override
  String get chatFilterNew => 'NEW';

  @override
  String get like => '좋아요';

  @override
  String get pass => '패스';

  @override
  String get languages => '언어';

  @override
  String get country => '국가';

  @override
  String get bio => '소개';

  @override
  String get startChat => '채팅 시작';

  @override
  String get yourLanguages => '내 언어';

  @override
  String get preferences => '설정';

  @override
  String get preferredLanguages => '추천 언어';

  @override
  String get prefTarget => '추천에 사용할 언어';

  @override
  String get save => '저장';

  @override
  String get name => '이름';

  @override
  String get age => '나이';

  @override
  String get occupation => '직업';

  @override
  String get interests => '관심사';

  @override
  String get gender => '성별';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get distance => '거리';

  @override
  String get distanceHint => '거리 범위';

  @override
  String get location => '위치';

  @override
  String get latitude => '위도';

  @override
  String get longitude => '경도';

  @override
  String get useCurrentLocation => '현재 위치 사용';

  @override
  String get locationUpdated => '위치가 업데이트되었습니다';

  @override
  String get locationServiceOff => '위치 서비스를 켜주세요';

  @override
  String get locationPermissionDenied => '위치 권한이 필요합니다';

  @override
  String get appLanguage => '앱 언어';

  @override
  String get languageNameKorean => '한국어';

  @override
  String get languageNameJapanese => '일본어';

  @override
  String get languageNameEnglish => '영어';

  @override
  String get onboardingTitle => '환영합니다';

  @override
  String get continueAction => '계속';

  @override
  String get loginTitle => '환영합니다';

  @override
  String get loginSubtitle => '이메일로 로그인하세요';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get signIn => '로그인';

  @override
  String get signUp => '회원가입';

  @override
  String get needAccount => '계정 만들기';

  @override
  String get haveAccount => '이미 계정이 있나요?';

  @override
  String get signOut => '로그아웃';

  @override
  String get refreshRecommendations => '새 추천 받기';

  @override
  String get distanceNear => '가까움';

  @override
  String get distanceMedium => '중간';

  @override
  String get distanceFar => '넓게';

  @override
  String get distanceNoLimit => '거리 제한 없음';

  @override
  String get distanceRangeLabel => '거리 범위';

  @override
  String get locationSet => '설정됨';

  @override
  String get locationUnset => '미설정';

  @override
  String get notificationsTitle => '알림 받기';

  @override
  String get notificationsSubtitle => '매칭 및 메시지 알림을 받을 수 있어요';

  @override
  String get queueSearchingTitle => '상대를 매칭 중입니다';

  @override
  String get queueSearchingSubtitle => '상대방을 찾는 중이에요. 잠시만 기다려주세요.';

  @override
  String get queueSearchStepDistance => '거리 확인 중...';

  @override
  String get queueSearchStepInterests => '공통 관심사 비교 중...';

  @override
  String get queueSearchStepExplore => '상대 탐색 중...';

  @override
  String get queueSearchStepAnalysis => '매칭 가능성 분석 중...';

  @override
  String get queueSearchTipPhoto => '사진이 있으면 응답률이 높아요';

  @override
  String get queueSearchTipBio => '자기소개가 있으면 매칭이 빨라요';

  @override
  String get queueSearchTipNewUsers => '지금 이 순간에도 새로운 사용자가 들어오고 있어요';

  @override
  String get queueTimeout => '응답 시간이 초과되었습니다';

  @override
  String get queueConnect => '연결하기';

  @override
  String get queueAccept => '수락';

  @override
  String get queueDecline => '거절';

  @override
  String get queueStop => '매칭 종료하기';

  @override
  String queueRemainingTime(Object seconds) {
    return '남은 시간 $seconds초';
  }

  @override
  String get queueResumeSubtitle => '다른 친구를 찾고 있어요 🌱';

  @override
  String get notificationMatchAcceptedToast => '💞 매칭이 완료됐어요. 지금 대화를 시작해보세요';

  @override
  String get notificationNewMessageToast => '💬 새 메시지가 도착했어요';

  @override
  String get notificationViewAction => '보기';

  @override
  String get likesInboxTitle => '알림';

  @override
  String get likesInboxEmpty => '새로 받은 알림 없음 💌';

  @override
  String get notificationsInboxTitle => '알림';

  @override
  String get notificationsInboxEmpty => '새로 받은 알림 없음 💌';

  @override
  String notificationsLikeText(Object name) {
    return '$name님이 좋아요를 눌렀어요';
  }

  @override
  String get notificationsMatchText => '새 매칭이 도착했어요';

  @override
  String get notificationsChatText => '새 메시지';

  @override
  String get notificationsSystemText => '알림';

  @override
  String get profileSaved => '저장되었습니다';

  @override
  String get retry => '다시 시도';

  @override
  String get matchFoundTitle => '매칭 성공!';

  @override
  String profileNameAge(Object age, Object name) {
    return '$name, $age';
  }

  @override
  String profileNameAgeCountry(Object age, Object country, Object name) {
    return '$name, $age · $country';
  }

  @override
  String get matchingSearchingTitle => '💗 새로운 인연을 찾고 있어요';

  @override
  String get matchingSearchingSubtitle => '잠시만 기다려 주세요';

  @override
  String get recommendCardSubtitle => '✨ 관심사가 잘 맞을지도 몰라요';

  @override
  String get noMatchTitle => '💭 아직 딱 맞는 친구를 찾지 못했어요';

  @override
  String get noMatchSubtitle => '관심사나 거리 범위를 살짝 바꿔볼까요?';

  @override
  String get noMatchAction => '관심사 수정하기';

  @override
  String get profileCompleteTitle => '프로필을 완성해야 추천을 받을 수 있어요';

  @override
  String get profileCompleteAction => '프로필 완성하기';

  @override
  String get chatSearchingEmoji => '💗';

  @override
  String get chatSearchingTitle => '조건에 맞는 친구를 찾고 있어요';

  @override
  String get chatSearchingSubtitle => '관심사가 비슷한 사람을 우선으로 찾고 있어요';

  @override
  String get chatMatchTitle => '💬 대화를 시작해볼까요?';

  @override
  String get chatMatchSubtitle => '지금 이 순간, 이야기해볼 사람이 있어요';

  @override
  String get chatStartButton => '💗 지금 채팅 시작하기';

  @override
  String get chatWaitingTitle => '🌱 아직 연결 중이에요';

  @override
  String get chatWaitingSubtitle => '조금만 더 기다려 주세요';

  @override
  String get matchingConsentTitle => '💬 지금 대화를 시작해볼까요?';

  @override
  String get matchingConsentSubtitle => '지금 이 순간, 이야기해볼 사람이 있어요';

  @override
  String get matchingConnectButton => '💗 연결하기';

  @override
  String get matchingSkipButton => '다음 매칭 기다리기';

  @override
  String get waitingForOtherUser => '상대방의 응답을 기다리고 있어요';

  @override
  String get firstMessageGuide => '✨ 대화를 시작해보세요!\n공통 관심사로 이야기를 꺼내면 좋아요.';

  @override
  String firstMessageSuggestions(Object interest) {
    return '요즘 $interest 자주 하세요?|$interest 좋아하게 된 계기가 뭐예요?|혹시 $interest 말고도 관심 있는 게 있나요?';
  }

  @override
  String firstMessageSuggestion1(Object interest) {
    return '요즘 $interest 자주 하세요?';
  }

  @override
  String firstMessageSuggestion2(Object interest) {
    return '$interest 좋아하게 된 계기가 뭐예요?';
  }

  @override
  String firstMessageSuggestion3(Object interest) {
    return '혹시 $interest 말고도 관심 있는 게 있나요?';
  }

  @override
  String get chatInputHint => '메시지를 입력하세요';

  @override
  String get chatError => '오류가 발생했습니다';

  @override
  String get chatExit => '채팅 종료하기';

  @override
  String get profileCompletionTitle => '프로필 완성도';

  @override
  String profileCompletionProgress(Object percent) {
    return '프로필 완성도 $percent%';
  }

  @override
  String get profileCompletionPhoto => '프로필 사진 추가';

  @override
  String get profileCompletionBio => '자기소개 작성';

  @override
  String get profileCompletionBasicInfo => '기본 정보 입력';

  @override
  String get profileCompletionCta => '매칭 시작하기';

  @override
  String get profileBioPlaceholder => '안녕하세요';

  @override
  String get profileBioPlaceholderAlt => '안녕하세요!';

  @override
  String get authVerifyIntro => '안전한 가입을 위해 인증이 필요합니다';

  @override
  String get authVerifyPhoneButton => '휴대폰 인증';

  @override
  String get authVerifyEmailButton => '이메일 인증';

  @override
  String get authPhoneLabel => '전화번호';

  @override
  String get authSendCode => '인증번호 보내기';

  @override
  String get authCodeLabel => '인증번호 입력';

  @override
  String get authVerifyCompleteButton => '인증 완료';

  @override
  String get authSendEmailVerification => '인증 메일 보내기';

  @override
  String get authCheckEmailVerified => '인증 완료 확인';

  @override
  String get authErrorInvalidEmail => '이메일 형식이 올바르지 않아요.';

  @override
  String get authErrorEmailInUse => '이미 사용 중인 이메일이에요.';

  @override
  String get authErrorWrongPassword => '비밀번호가 올바르지 않아요.';

  @override
  String get authErrorUserNotFound => '등록된 계정을 찾을 수 없어요.';

  @override
  String get authErrorTooManyRequests => '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';

  @override
  String get authErrorInvalidVerificationCode => '인증번호가 올바르지 않아요.';

  @override
  String get authErrorInvalidVerificationId => '인증 세션이 만료되었어요. 다시 시도해 주세요.';

  @override
  String get authErrorVerificationFailed => '인증 처리에 실패했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get authErrorVerificationRequired => '인증을 완료해야 회원가입할 수 있어요.';

  @override
  String get authErrorEmptyEmailPassword => '이메일과 비밀번호를 입력해 주세요.';

  @override
  String get authErrorPhoneEmpty => '전화번호를 입력해 주세요.';

  @override
  String get authErrorCodeEmpty => '인증번호를 입력해 주세요.';

  @override
  String get authErrorGeneric => '요청을 처리할 수 없어요. 다시 시도해 주세요.';

  @override
  String get uploadErrorPermission => '사진 접근 권한이 필요해요. 설정에서 권한을 허용해 주세요.';

  @override
  String get uploadErrorCanceled => '업로드가 취소되었어요. 다시 시도해 주세요.';

  @override
  String get uploadErrorUnauthorized => '인증이 만료되었어요. 다시 로그인해 주세요.';

  @override
  String get uploadErrorNetwork => '네트워크가 불안정해요. 잠시 후 다시 시도해 주세요.';

  @override
  String get uploadErrorUnknown => '알 수 없는 오류가 발생했어요. 다시 시도해 주세요.';

  @override
  String get uploadErrorFailed => '업로드에 실패했어요. 다시 시도해 주세요.';

  @override
  String get uploadErrorFileRead => '사진을 읽을 수 없어요. 다른 사진을 선택해 주세요.';

  @override
  String get reportConfirm => '신고';

  @override
  String get reportReasonSpam => '스팸/광고';

  @override
  String get reportAction => '신고하기';

  @override
  String get reportTitle => '신고 사유를 선택해 주세요';

  @override
  String get reportReasonHarassment => '괴롭힘/불쾌한 행동';

  @override
  String get reportReasonInappropriate => '부적절한 콘텐츠';

  @override
  String get reportCancel => '취소';

  @override
  String get reportSubmitted => '신고가 접수되었습니다';

  @override
  String get reportReasonOther => '기타';

  @override
  String get protectionLimitedMessage => '현재 보호 혜택을 사용할 수 없어요.';

  @override
  String get protectionBlockedMessage => '현재 매칭이 제한되어 있어요.';

  @override
  String get resetEmailSentMessage => '입력하신 이메일로 가입된 계정이 있다면\\n안내 메일을 보내드렸어요.';

  @override
  String get findAccountTitle => '계정 찾기';

  @override
  String get findAccountDescription =>
      '가입할 때 사용한 이메일을 입력해주세요.\\n계정이 있다면 재설정 안내를 보내드릴게요.';

  @override
  String get sendResetEmail => '안내 메일 보내기';

  @override
  String get loginForgotCredential => '아이디나 비밀번호가 생각나지 않나요?';

  @override
  String get adminTitle => '관리자 모더레이션';

  @override
  String get adminUidLabel => '사용자 UID';

  @override
  String get adminLoadUser => '사용자 불러오기';

  @override
  String get adminNotAuthorized => '관리자 권한이 필요합니다';

  @override
  String get adminModerationLevel => '제재 레벨';

  @override
  String get adminTotalReports => '신고 누적';

  @override
  String get adminProtectionEligible => '보호 혜택 대상';

  @override
  String get adminHardFlags => '강한 플래그';

  @override
  String get adminHardFlagSevere => '심각';

  @override
  String get adminHardFlagSexual => '성적';

  @override
  String get adminHardFlagViolence => '폭력';

  @override
  String get adminHardFlagSpam => '스팸';

  @override
  String get adminProtectionActive => '보호 활성';

  @override
  String get adminProtectionExpiresAt => '보호 만료';

  @override
  String get adminProtectionBanActive => '보호 금지';

  @override
  String get adminProtectionBanUntil => '금지 종료';

  @override
  String get adminProtectionBanReason => '금지 사유';

  @override
  String get adminSave => '저장하기';

  @override
  String get adminSaved => '저장되었습니다';

  @override
  String get adminLoadFailed => '사용자 정보를 불러오지 못했어요';
}
