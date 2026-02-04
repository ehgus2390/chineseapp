// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Kkiri Dating';

  @override
  String get tabRecommend => 'おすすめ';

  @override
  String get tabNearby => '近く';

  @override
  String get tabFeed => 'フィード';

  @override
  String get tabChat => 'チャット';

  @override
  String get tabProfile => 'プロフィール';

  @override
  String get discoverTitle => 'おすすめ';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get discoverEmpty => '条件に合うプロフィールがありません';

  @override
  String get chatEmpty => '条件に合う人がいません';

  @override
  String get chatTitle => 'チャット';

  @override
  String get chatFilterAll => 'すべて';

  @override
  String get chatFilterLikes => 'いいね';

  @override
  String get chatFilterNew => 'NEW';

  @override
  String get like => 'いいね';

  @override
  String get pass => 'パス';

  @override
  String get languages => '言語';

  @override
  String get country => '国';

  @override
  String get bio => '自己紹介';

  @override
  String get startChat => 'チャット開始';

  @override
  String get yourLanguages => '自分の言語';

  @override
  String get preferences => '設定';

  @override
  String get preferredLanguages => 'おすすめ言語';

  @override
  String get prefTarget => 'おすすめに使う言語';

  @override
  String get save => '保存';

  @override
  String get name => '名前';

  @override
  String get age => '年齢';

  @override
  String get occupation => '職業';

  @override
  String get interests => '興味';

  @override
  String get gender => '性別';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get distance => '距離';

  @override
  String get distanceHint => '距離範囲';

  @override
  String get location => '位置';

  @override
  String get latitude => '緯度';

  @override
  String get longitude => '経度';

  @override
  String get useCurrentLocation => '現在地を使用';

  @override
  String get locationUpdated => '位置が更新されました';

  @override
  String get locationServiceOff => '位置情報サービスをオンにしてください';

  @override
  String get locationPermissionDenied => '位置情報の権限が必要です';

  @override
  String get appLanguage => 'アプリ言語';

  @override
  String get languageNameKorean => '韓国語';

  @override
  String get languageNameJapanese => '日本語';

  @override
  String get languageNameEnglish => '英語';

  @override
  String get onboardingTitle => 'ようこそ';

  @override
  String get continueAction => 'Continue';

  @override
  String get loginTitle => 'ようこそ';

  @override
  String get loginSubtitle => 'メールでログイン';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get signIn => 'ログイン';

  @override
  String get signUp => '会員登録';

  @override
  String get needAccount => 'アカウントを作成';

  @override
  String get haveAccount => 'すでにアカウントがありますか？';

  @override
  String get signOut => 'ログアウト';

  @override
  String get refreshRecommendations => '新しいおすすめを取得';

  @override
  String get distanceNear => '近い';

  @override
  String get distanceMedium => '中間';

  @override
  String get distanceFar => '広め';

  @override
  String get distanceNoLimit => '距離制限なし';

  @override
  String get distanceRangeLabel => '距離範囲';

  @override
  String get locationSet => '設定済み';

  @override
  String get locationUnset => '未設定';

  @override
  String get notificationsTitle => '通知を受け取る';

  @override
  String get notificationsSubtitle => 'マッチやメッセージ通知を受け取れます';

  @override
  String get queueSearchingTitle => '相手をマッチ中です';

  @override
  String get queueSearchingSubtitle => '相手を探しています。少しお待ちください。';

  @override
  String get queueSearchStepDistance => '距離を確認中…';

  @override
  String get queueSearchStepInterests => '共通の興味を比較中…';

  @override
  String get queueSearchStepExplore => '相手を探しています…';

  @override
  String get queueSearchStepAnalysis => 'マッチの可能性を分析中…';

  @override
  String get queueSearchTipPhoto => '写真があると反応率が上がります';

  @override
  String get queueSearchTipBio => '自己紹介があるとマッチが早くなります';

  @override
  String get queueSearchTipNewUsers => '今この瞬間も新しいユーザーが参加しています';

  @override
  String get queueTimeout => '応答時間が終了しました';

  @override
  String get queueConnect => 'つなぐ';

  @override
  String get queueAccept => '承認';

  @override
  String get queueDecline => '拒否';

  @override
  String get queueStop => 'マッチング終了';

  @override
  String queueRemainingTime(Object seconds) {
    return '残り時間 $seconds秒';
  }

  @override
  String get queueResumeSubtitle => '別の友だちを探しています 🌱';

  @override
  String get notificationMatchAcceptedToast => '💞 マッチが成立しました。今すぐ話してみましょう';

  @override
  String get notificationNewMessageToast => '💬 新しいメッセージが届きました';

  @override
  String get notificationViewAction => '見る';

  @override
  String get likesInboxTitle => '通知';

  @override
  String get likesInboxEmpty => '新着通知はありません 💌';

  @override
  String get notificationsInboxTitle => '通知';

  @override
  String get notificationsInboxEmpty => '新着通知はありません 💌';

  @override
  String notificationsLikeText(Object name) {
    return '$nameさんがいいねしました';
  }

  @override
  String get notificationsMatchText => '新しいマッチがあります';

  @override
  String get notificationsChatText => '新しいメッセージ';

  @override
  String get notificationsSystemText => '通知';

  @override
  String get profileSaved => '保存しました';

  @override
  String get retry => '再試行';

  @override
  String get matchFoundTitle => 'マッチしました！';

  @override
  String profileNameAge(Object age, Object name) {
    return '$name, $age';
  }

  @override
  String profileNameAgeCountry(Object age, Object country, Object name) {
    return '$name, $age · $country';
  }

  @override
  String get matchingSearchingTitle => '💗 新しい出会いを探しています';

  @override
  String get matchingSearchingSubtitle => '少しだけお待ちください';

  @override
  String get recommendCardSubtitle => '✨ 興味が合うかもしれません';

  @override
  String get noMatchTitle => '💭 まだぴったりの人が見つかりません';

  @override
  String get noMatchSubtitle => '興味や距離範囲を少し調整してみましょう';

  @override
  String get noMatchAction => '興味を編集';

  @override
  String get profileCompleteTitle => 'プロフィールを完成するとおすすめが表示されます';

  @override
  String get profileCompleteAction => 'プロフィールを完成';

  @override
  String get chatSearchingEmoji => '💗';

  @override
  String get chatSearchingTitle => '条件に合う友だちを探しています';

  @override
  String get chatSearchingSubtitle => '似た興味の人を優先して探しています';

  @override
  String get chatMatchTitle => '💬 お話ししてみませんか？';

  @override
  String get chatMatchSubtitle => '今この瞬間、話せる相手がいます';

  @override
  String get chatStartButton => '💗 今すぐチャットを始める';

  @override
  String get chatWaitingTitle => '🌱 まだ接続中です';

  @override
  String get chatWaitingSubtitle => 'もう少しお待ちください';

  @override
  String get matchingConsentTitle => '💬 今お話ししてみませんか？';

  @override
  String get matchingConsentSubtitle => '今この瞬間、話せる相手がいます';

  @override
  String get matchingConnectButton => '💗 つなぐ';

  @override
  String get matchingSkipButton => '次のマッチを待つ';

  @override
  String get waitingForOtherUser => '相手の返答を待っています';

  @override
  String get firstMessageGuide => '✨ 会話を始めてみましょう！\n共通の興味から話すと良いです。';

  @override
  String firstMessageSuggestions(Object interest) {
    return '最近$interestはよくしますか？|$interestを好きになったきっかけは何ですか？|$interest以外にも興味はありますか？';
  }

  @override
  String firstMessageSuggestion1(Object interest) {
    return '最近$interestはよくしますか？';
  }

  @override
  String firstMessageSuggestion2(Object interest) {
    return '$interestを好きになったきっかけは何ですか？';
  }

  @override
  String firstMessageSuggestion3(Object interest) {
    return '$interest以外にも興味はありますか？';
  }

  @override
  String get chatInputHint => 'メッセージを入力';

  @override
  String get chatError => 'エラーが発生しました';

  @override
  String get chatExit => 'チャットを終了';

  @override
  String get profileCompletionTitle => 'プロフィール完成度';

  @override
  String profileCompletionProgress(Object percent) {
    return 'プロフィール完成度 $percent%';
  }

  @override
  String get profileCompletionPhoto => 'プロフィール写真を追加';

  @override
  String get profileCompletionBio => '自己紹介を書く';

  @override
  String get profileCompletionBasicInfo => '基本情報を入力';

  @override
  String get profileCompletionCta => 'マッチを始める';

  @override
  String get profileBioPlaceholder => 'こんにちは';

  @override
  String get profileBioPlaceholderAlt => 'こんにちは！';

  @override
  String get authVerifyIntro => '安全のため、認証が必要です';

  @override
  String get authVerifyPhoneButton => '電話番号認証';

  @override
  String get authVerifyEmailButton => 'メール認証';

  @override
  String get authPhoneLabel => '電話番号';

  @override
  String get authSendCode => '認証コードを送信';

  @override
  String get authCodeLabel => '認証コードを入力';

  @override
  String get authVerifyCompleteButton => '認証完了';

  @override
  String get authSendEmailVerification => '認証メールを送信';

  @override
  String get authCheckEmailVerified => '認証完了を確認';

  @override
  String get authErrorInvalidEmail => '有効なメールアドレスを入力してください。';

  @override
  String get authErrorEmailInUse => 'このメールアドレスは既に使用されています。';

  @override
  String get authErrorWrongPassword => 'パスワードが正しくありません。';

  @override
  String get authErrorUserNotFound => 'アカウントが見つかりません。';

  @override
  String get authErrorTooManyRequests => 'リクエストが多すぎます。しばらくしてから再試行してください。';

  @override
  String get authErrorInvalidVerificationCode => '認証コードが正しくありません。';

  @override
  String get authErrorInvalidVerificationId => '認証セッションが期限切れです。再度お試しください。';

  @override
  String get authErrorVerificationFailed => '認証に失敗しました。しばらくしてから再試行してください。';

  @override
  String get authErrorVerificationRequired => '会員登録には認証が必要です。';

  @override
  String get authErrorEmptyEmailPassword => 'メールアドレスとパスワードを入力してください。';

  @override
  String get authErrorPhoneEmpty => '電話番号を入力してください。';

  @override
  String get authErrorCodeEmpty => '認証コードを入力してください。';

  @override
  String get authErrorGeneric => '処理できませんでした。もう一度お試しください。';

  @override
  String get uploadErrorPermission => '写真へのアクセス許可が必要です。設定で許可してください。';

  @override
  String get uploadErrorCanceled => 'アップロードがキャンセルされました。もう一度お試しください。';

  @override
  String get uploadErrorUnauthorized => '認証が切れました。再度ログインしてください。';

  @override
  String get uploadErrorNetwork => 'ネットワークが不安定です。少し時間をおいて再試行してください。';

  @override
  String get uploadErrorUnknown => '不明なエラーが発生しました。再試行してください。';

  @override
  String get uploadErrorFailed => 'アップロードに失敗しました。再試行してください。';

  @override
  String get uploadErrorFileRead => '写真を読み込めませんでした。別の写真を選んでください。';

  @override
  String get reportConfirm => '通報';

  @override
  String get reportReasonSpam => 'スパム・広告';

  @override
  String get reportAction => '通報する';

  @override
  String get reportTitle => '通報理由を選んでください';

  @override
  String get reportReasonHarassment => '嫌がらせ・不快な行為';

  @override
  String get reportReasonInappropriate => '不適切なコンテンツ';

  @override
  String get reportCancel => 'キャンセル';

  @override
  String get reportSubmitted => '通報を受け付けました';

  @override
  String get reportReasonOther => 'その他';
}
