// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'キリ';

  @override
  String get home => 'ホーム';

  @override
  String get profile => 'プロフィール';

  @override
  String get friends => '友だち';

  @override
  String get chat => 'チャット';

  @override
  String get map => '地図';

  @override
  String get board => 'コミュニティ';

  @override
  String get settings => '設定';

  @override
  String get welcome => 'Kkiriへようこそ';

  @override
  String get welcomeSubtitle => '韓国での最初の友だちを見つけましょう';

  @override
  String get findMyPeople => '仲間を探す';

  @override
  String get peopleNearYou => '近くの人';

  @override
  String get seeMore => 'もっと見る';

  @override
  String get myCommunities => '参加中のコミュニティ';

  @override
  String get manage => '管理';

  @override
  String get smallEvents => '小規模な集まり';

  @override
  String get smallEventsSubtitle => '混雑せず、自然に出会えます。';

  @override
  String get sayHi => 'あいさつする';

  @override
  String get sendRequest => 'メッセージを送る';

  @override
  String get profileSaved => 'プロフィールが保存されました';

  @override
  String get changePhoto => '写真を変更';

  @override
  String get displayName => 'ニックネーム';

  @override
  String get age => '年齢';

  @override
  String get gender => '性別';

  @override
  String get bio => '自己紹介';

  @override
  String get save => '保存';

  @override
  String get genderMale => '男性';

  @override
  String get genderFemale => '女性';

  @override
  String get genderOther => 'その他';

  @override
  String get language => '言語';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageKorean => '韓国語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageChinese => '中国語';

  @override
  String get report => '通報';

  @override
  String get block => 'ブロック';

  @override
  String get reportDescription => '投稿、コメント、またはユーザーを通報します。';

  @override
  String get blockDescription => 'ブロックしたユーザーの投稿やチャットは表示されません。';

  @override
  String get anonymous => '匿名';

  @override
  String get universityCommunityTitle => '大学コミュニティ';

  @override
  String get universityCommunitySubtitle => 'あなたのキャンパス限定';

  @override
  String get universityCommunityEmpty => 'キャンパスのコミュニティにはまだ投稿がありません。';

  @override
  String get universityCommunityMissing => '大学コミュニティが見つかりませんでした。';

  @override
  String get homeCampusLabel => 'キャンパス';

  @override
  String get homeCampusFallback => 'キャンパスを設定してください';

  @override
  String get homeFeedEmpty => 'キャンパスに新しい投稿がありません。';

  @override
  String get categoryFood => '食事';

  @override
  String get categoryClasses => '授業';

  @override
  String get shareLocation => '位置情報共有';

  @override
  String get shareLocationDesc => '내 주변 친구 추천에 사용됩니다';

  @override
  String get logout => 'ログアウト';

  @override
  String get categoryHousing => '住宅';

  @override
  String get categoryLifeInKorea => '韓国生活';

  @override
  String get writePostTitle => '投稿作成';

  @override
  String get writePostHint => '投稿を入力してください';

  @override
  String get cancel => 'キャンセル';

  @override
  String get submitPost => '投稿を送信';

  @override
  String get post => '投稿';

  @override
  String get comment => 'コメント';

  @override
  String get like => 'いいね';

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes分前';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours時間前';
  }

  @override
  String daysAgo(Object days) {
    return '$days日前';
  }

  @override
  String get login => 'ログイン';

  @override
  String get requireEmailLoginTitle => 'メールログインが必要です';

  @override
  String requireEmailLoginMessage(Object featureName) {
    return '$featureNameを利用するにはメールログインが必要です。';
  }

  @override
  String get loginAction => 'ログインする';

  @override
  String get profileLoginRequiredMessage => 'ログイン後に利用できる機能です';

  @override
  String get chatLoginRequiredMessage => 'チャットの利用にはログインが必要です。';
}
