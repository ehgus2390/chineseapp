import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<String> supportedLanguageCodes = <String>['ko', 'en', 'zh', 'hi', 'ja'];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = <String, Map<String, String>>{
    'en': <String, String>{
      'appTitle': 'KKIRI',
      'tabProfile': 'Profile',
      'tabFriends': 'Friends',
      'tabChats': 'Chats',
      'tabCommunity': 'Community',
      'searchHint': 'Search friends, chats or posts',
      'addFriend': 'Add friend by ID',
      'addFriendDescription': 'Enter a user ID to send a friend request instantly.',
      'addFriendPlaceholder': 'User ID',
      'addFriendButton': 'Add',
      'cancel': 'Cancel',
      'ok': 'OK',
      'friendAdded': 'Friend added to your list.',
      'friendAlready': 'You are already friends.',
      'friendNotFound': 'No user found with that ID.',
      'settings': 'Settings',
      'changeProfilePhoto': 'Change profile photo',
      'notificationSettings': 'Notification preferences',
      'languageSettings': 'Language',
      'languageSettingsDescription': 'Choose the language for the app interface.',
      'notificationMessages': 'Message alerts',
      'notificationFriendRequests': 'Friend requests',
      'notificationCommunityUpdates': 'Community updates',
      'customerSupport': 'Customer support',
      'supportEmail': 'support@kkiri.app',
      'languageUpdated': 'Language updated.',
      'myProfile': 'My profile',
      'statusMessage': 'Status message',
      'editStatus': 'Edit status',
      'languages': 'Languages',
      'aboutMe': 'About me',
      'nearbyFriends': 'Nearby friends',
      'radiusLabel': '{distance} km radius from you',
      'myFriends': 'My friends',
      'emptyFriends': 'Add friends to start chatting!',
      'startChat': 'Start chat',
      'viewProfile': 'View profile',
      'chatListEmpty': 'No active chats yet. Say hello to someone new!',
      'messagePlaceholder': 'Type a message',
      'send': 'Send',
      'communityTitle': 'Community board',
      'popularPosts': 'Popular posts',
      'allPosts': 'All posts',
      'writePost': 'Write a post',
      'postPlaceholder': 'Share your story with the community...',
      'postButton': 'Post',
      'like': 'Like',
      'comment': 'Comment',
      'comments': 'Comments',
      'noComments': 'Be the first to comment!',
      'addComment': 'Add a comment',
      'searchFriends': 'Friends',
      'searchChats': 'Chats',
      'searchPosts': 'Posts',
      'profileDetail': 'Profile details',
      'customerSupportDescription': 'Reach out to us anytime.',
      'insightProfileUpdate': 'Keep your profile updated to meet more friends.',
      'insightShareTips': 'Share local tips to appear in the popular posts feed!',
      'insightNewPost': 'You shared a new story with the community.',
    },
    'ko': <String, String>{
      'appTitle': '끼리',
      'tabProfile': '내 프로필',
      'tabFriends': '친구',
      'tabChats': '채팅',
      'tabCommunity': '게시판',
      'searchHint': '친구, 채팅, 게시글 검색',
      'addFriend': '아이디로 친구 추가',
      'addFriendDescription': '사용자 아이디를 입력하면 바로 친구를 맺을 수 있어요.',
      'addFriendPlaceholder': '사용자 아이디',
      'addFriendButton': '추가',
      'cancel': '취소',
      'ok': '확인',
      'friendAdded': '친구 목록에 추가했어요.',
      'friendAlready': '이미 친구입니다.',
      'friendNotFound': '해당 아이디의 사용자가 없어요.',
      'settings': '설정',
      'changeProfilePhoto': '프로필 사진 바꾸기',
      'notificationSettings': '알림 설정',
      'languageSettings': '언어 설정',
      'languageSettingsDescription': '앱에서 사용할 언어를 선택하세요.',
      'notificationMessages': '메시지 알림',
      'notificationFriendRequests': '친구 요청',
      'notificationCommunityUpdates': '커뮤니티 소식',
      'customerSupport': '고객센터',
      'supportEmail': 'support@kkiri.app',
      'languageUpdated': '언어가 변경되었습니다.',
      'myProfile': '내 프로필',
      'statusMessage': '상태 메시지',
      'editStatus': '상태 메시지 수정',
      'languages': '가능 언어',
      'aboutMe': '소개글',
      'nearbyFriends': '내 주변 친구',
      'radiusLabel': '나를 기준으로 {distance}km 반경',
      'myFriends': '내가 추가한 친구',
      'emptyFriends': '친구를 추가하고 대화를 시작해보세요!',
      'startChat': '대화 시작하기',
      'viewProfile': '프로필 보기',
      'chatListEmpty': '아직 대화가 없어요. 먼저 인사를 건네보세요!',
      'messagePlaceholder': '메시지를 입력하세요',
      'send': '보내기',
      'communityTitle': '커뮤니티',
      'popularPosts': '인기 게시글',
      'allPosts': '전체 게시글',
      'writePost': '글쓰기',
      'postPlaceholder': '커뮤니티에 이야기를 공유해보세요...',
      'postButton': '등록',
      'like': '좋아요',
      'comment': '댓글',
      'comments': '댓글',
      'noComments': '가장 먼저 댓글을 남겨보세요!',
      'addComment': '댓글 달기',
      'searchFriends': '친구',
      'searchChats': '채팅',
      'searchPosts': '게시글',
      'profileDetail': '프로필 상세',
      'customerSupportDescription': '언제든 문의해주세요.',
      'insightProfileUpdate': '프로필을 자주 업데이트하면 더 많은 친구를 만날 수 있어요.',
      'insightShareTips': '지역 정보를 공유하면 인기 게시글에 올라갈 수 있어요!',
      'insightNewPost': '새로운 이야기를 커뮤니티에 남겼어요.',
    },
    'zh': <String, String>{
      'appTitle': 'KKIRI',
      'tabProfile': '我的檔案',
      'tabFriends': '朋友',
      'tabChats': '聊天',
      'tabCommunity': '社群',
      'searchHint': '搜尋朋友、聊天或貼文',
      'addFriend': '用 ID 加好友',
      'addFriendDescription': '輸入使用者 ID 立即加好友。',
      'addFriendPlaceholder': '使用者 ID',
      'addFriendButton': '加入',
      'cancel': '取消',
      'ok': '確定',
      'friendAdded': '已加入好友清單。',
      'friendAlready': '你們已經是朋友了。',
      'friendNotFound': '找不到此 ID 的使用者。',
      'settings': '設定',
      'changeProfilePhoto': '更換頭像',
      'notificationSettings': '通知設定',
      'languageSettings': '語言',
      'languageSettingsDescription': '選擇介面語言。',
      'notificationMessages': '訊息通知',
      'notificationFriendRequests': '好友邀請',
      'notificationCommunityUpdates': '社群更新',
      'customerSupport': '客服中心',
      'supportEmail': 'support@kkiri.app',
      'languageUpdated': '語言已更新。',
      'myProfile': '我的檔案',
      'statusMessage': '狀態訊息',
      'editStatus': '編輯狀態',
      'languages': '語言',
      'aboutMe': '自我介紹',
      'nearbyFriends': '附近的朋友',
      'radiusLabel': '以你為中心的 {distance} 公里',
      'myFriends': '我的好友',
      'emptyFriends': '快去加好友開始聊天吧！',
      'startChat': '開始聊天',
      'viewProfile': '檢視檔案',
      'chatListEmpty': '還沒有聊天，主動打個招呼吧！',
      'messagePlaceholder': '輸入訊息',
      'send': '傳送',
      'communityTitle': '社群版',
      'popularPosts': '熱門貼文',
      'allPosts': '所有貼文',
      'writePost': '寫貼文',
      'postPlaceholder': '與社群分享你的故事...',
      'postButton': '發布',
      'like': '讚',
      'comment': '留言',
      'comments': '留言',
      'noComments': '搶先留言吧！',
      'addComment': '新增留言',
      'searchFriends': '朋友',
      'searchChats': '聊天',
      'searchPosts': '貼文',
      'profileDetail': '檔案資訊',
      'customerSupportDescription': '歡迎隨時聯繫我們。',
      'insightProfileUpdate': '常常更新個人檔案會更容易結交朋友。',
      'insightShareTips': '分享在地資訊就能進入熱門貼文！',
      'insightNewPost': '你剛剛在社群分享了一則新貼文。',
    },
    'hi': <String, String>{
      'appTitle': 'क्किरी',
      'tabProfile': 'प्रोफ़ाइल',
      'tabFriends': 'दोस्त',
      'tabChats': 'चैट',
      'tabCommunity': 'समुदाय',
      'searchHint': 'दोस्त, चैट या पोस्ट खोजें',
      'addFriend': 'आईडी से दोस्त जोड़ें',
      'addFriendDescription': 'उपयोगकर्ता आईडी दर्ज करें और तुरंत दोस्त बनें।',
      'addFriendPlaceholder': 'उपयोगकर्ता आईडी',
      'addFriendButton': 'जोड़ें',
      'cancel': 'रद्द करें',
      'ok': 'ठीक है',
      'friendAdded': 'दोस्त सूची में जोड़ दिया गया।',
      'friendAlready': 'आप पहले से ही दोस्त हैं।',
      'friendNotFound': 'उस आईडी वाला कोई उपयोगकर्ता नहीं मिला।',
      'settings': 'सेटिंग्स',
      'changeProfilePhoto': 'प्रोफ़ाइल फोटो बदलें',
      'notificationSettings': 'सूचना सेटिंग्स',
      'languageSettings': 'भाषा',
      'languageSettingsDescription': 'ऐप की भाषा चुनें।',
      'notificationMessages': 'संदेश अलर्ट',
      'notificationFriendRequests': 'दोस्ती अनुरोध',
      'notificationCommunityUpdates': 'समुदाय अपडेट्स',
      'customerSupport': 'ग्राहक सहायता',
      'supportEmail': 'support@kkiri.app',
      'languageUpdated': 'भाषा अपडेट कर दी गई है।',
      'myProfile': 'मेरी प्रोफ़ाइल',
      'statusMessage': 'स्टेटस संदेश',
      'editStatus': 'स्टेटस संपादित करें',
      'languages': 'भाषाएँ',
      'aboutMe': 'मेरे बारे में',
      'nearbyFriends': 'आस-पास के दोस्त',
      'radiusLabel': 'आपके आसपास {distance} किमी का क्षेत्र',
      'myFriends': 'मेरे दोस्त',
      'emptyFriends': 'दोस्त जोड़ें और बातचीत शुरू करें!',
      'startChat': 'चैट शुरू करें',
      'viewProfile': 'प्रोफ़ाइल देखें',
      'chatListEmpty': 'अभी कोई चैट नहीं है। किसी को नमस्ते कहें!',
      'messagePlaceholder': 'संदेश लिखें',
      'send': 'भेजें',
      'communityTitle': 'समुदाय बोर्ड',
      'popularPosts': 'लोकप्रिय पोस्ट',
      'allPosts': 'सभी पोस्ट',
      'writePost': 'पोस्ट लिखें',
      'postPlaceholder': 'समुदाय के साथ अपनी कहानी साझा करें...',
      'postButton': 'पोस्ट करें',
      'like': 'पसंद',
      'comment': 'टिप्पणी',
      'comments': 'टिप्पणियाँ',
      'noComments': 'सबसे पहले टिप्पणी करें!',
      'addComment': 'टिप्पणी जोड़ें',
      'searchFriends': 'दोस्त',
      'searchChats': 'चैट',
      'searchPosts': 'पोस्ट',
      'profileDetail': 'प्रोफ़ाइल विवरण',
      'customerSupportDescription': 'कभी भी हमसे संपर्क करें।',
      'insightProfileUpdate': 'प्रोफ़ाइल अपडेट रखने से नए दोस्त जल्दी मिलते हैं।',
      'insightShareTips': 'स्थानीय टिप्स साझा करें और लोकप्रिय पोस्ट में दिखें!',
      'insightNewPost': 'आपने समुदाय में नई कहानी साझा की है।',
    },
    'ja': <String, String>{
      'appTitle': 'キリ',
      'tabProfile': 'プロフィール',
      'tabFriends': '友だち',
      'tabChats': 'トーク',
      'tabCommunity': 'コミュニティ',
      'searchHint': '友だち・トーク・投稿を検索',
      'addFriend': 'IDで友だち追加',
      'addFriendDescription': 'ユーザーIDを入力するとすぐに友だちになれます。',
      'addFriendPlaceholder': 'ユーザーID',
      'addFriendButton': '追加',
      'cancel': 'キャンセル',
      'ok': '確認',
      'friendAdded': '友だちリストに追加しました。',
      'friendAlready': 'すでに友だちです。',
      'friendNotFound': '該当するIDのユーザーが見つかりません。',
      'settings': '設定',
      'changeProfilePhoto': 'プロフィール写真を変更',
      'notificationSettings': '通知設定',
      'languageSettings': '言語',
      'languageSettingsDescription': 'アプリの表示言語を選択してください。',
      'notificationMessages': 'メッセージ通知',
      'notificationFriendRequests': '友だちリクエスト',
      'notificationCommunityUpdates': 'コミュニティのお知らせ',
      'customerSupport': 'カスタマーサポート',
      'supportEmail': 'support@kkiri.app',
      'languageUpdated': '言語を変更しました。',
      'myProfile': 'マイプロフィール',
      'statusMessage': 'ステータスメッセージ',
      'editStatus': 'ステータスを編集',
      'languages': '話せる言語',
      'aboutMe': '自己紹介',
      'nearbyFriends': '近くの友だち',
      'radiusLabel': '現在地から半径{distance}km',
      'myFriends': '友だちリスト',
      'emptyFriends': '友だちを追加して会話を始めましょう！',
      'startChat': 'チャットを開始',
      'viewProfile': 'プロフィールを見る',
      'chatListEmpty': 'まだトークがありません。まずは挨拶してみましょう！',
      'messagePlaceholder': 'メッセージを入力',
      'send': '送信',
      'communityTitle': 'コミュニティ',
      'popularPosts': '人気の投稿',
      'allPosts': 'すべての投稿',
      'writePost': '投稿する',
      'postPlaceholder': 'コミュニティにストーリーを共有しましょう...',
      'postButton': '投稿',
      'like': 'いいね',
      'comment': 'コメント',
      'comments': 'コメント',
      'noComments': '最初のコメントを残しましょう！',
      'addComment': 'コメントを書く',
      'searchFriends': '友だち',
      'searchChats': 'トーク',
      'searchPosts': '投稿',
      'profileDetail': 'プロフィール詳細',
      'customerSupportDescription': 'いつでもお問い合わせください。',
      'insightProfileUpdate': 'プロフィールをこまめに更新すると友だちが増えます。',
      'insightShareTips': '地域の情報を共有すると人気の投稿に載れますよ！',
      'insightNewPost': 'コミュニティに新しい投稿をしました。',
    },
  };

  String _lookup(String key) {
    final String code = locale.languageCode;
    final Map<String, String>? table = _localizedValues[code];
    if (table != null && table.containsKey(key)) {
      return table[key]!;
    }
    return _localizedValues['en']![key] ?? key;
  }

  String get appTitle => _lookup('appTitle');
  String get tabProfile => _lookup('tabProfile');
  String get tabFriends => _lookup('tabFriends');
  String get tabChats => _lookup('tabChats');
  String get tabCommunity => _lookup('tabCommunity');
  String get searchHint => _lookup('searchHint');
  String get addFriend => _lookup('addFriend');
  String get addFriendDescription => _lookup('addFriendDescription');
  String get addFriendPlaceholder => _lookup('addFriendPlaceholder');
  String get addFriendButton => _lookup('addFriendButton');
  String get cancel => _lookup('cancel');
  String get ok => _lookup('ok');
  String get friendAdded => _lookup('friendAdded');
  String get friendAlready => _lookup('friendAlready');
  String get friendNotFound => _lookup('friendNotFound');
  String get settings => _lookup('settings');
  String get changeProfilePhoto => _lookup('changeProfilePhoto');
  String get notificationSettings => _lookup('notificationSettings');
  String get languageSettings => _lookup('languageSettings');
  String get languageSettingsDescription => _lookup('languageSettingsDescription');
  String get notificationMessages => _lookup('notificationMessages');
  String get notificationFriendRequests => _lookup('notificationFriendRequests');
  String get notificationCommunityUpdates => _lookup('notificationCommunityUpdates');
  String get customerSupport => _lookup('customerSupport');
  String get supportEmail => _lookup('supportEmail');
  String get languageUpdated => _lookup('languageUpdated');
  String get myProfile => _lookup('myProfile');
  String get statusMessage => _lookup('statusMessage');
  String get editStatus => _lookup('editStatus');
  String get languagesLabel => _lookup('languages');
  String get aboutMe => _lookup('aboutMe');
  String get nearbyFriends => _lookup('nearbyFriends');
  String radiusLabel(String distance) => _lookup('radiusLabel').replaceAll('{distance}', distance);
  String get myFriends => _lookup('myFriends');
  String get emptyFriends => _lookup('emptyFriends');
  String get startChat => _lookup('startChat');
  String get viewProfile => _lookup('viewProfile');
  String get chatListEmpty => _lookup('chatListEmpty');
  String get messagePlaceholder => _lookup('messagePlaceholder');
  String get send => _lookup('send');
  String get communityTitle => _lookup('communityTitle');
  String get popularPosts => _lookup('popularPosts');
  String get allPosts => _lookup('allPosts');
  String get writePost => _lookup('writePost');
  String get postPlaceholder => _lookup('postPlaceholder');
  String get postButton => _lookup('postButton');
  String get like => _lookup('like');
  String get comment => _lookup('comment');
  String get comments => _lookup('comments');
  String get noComments => _lookup('noComments');
  String get addComment => _lookup('addComment');
  String get searchFriendsLabel => _lookup('searchFriends');
  String get searchChatsLabel => _lookup('searchChats');
  String get searchPostsLabel => _lookup('searchPosts');
  String get profileDetail => _lookup('profileDetail');
  String get customerSupportDescription => _lookup('customerSupportDescription');
  String get insightProfileUpdate => _lookup('insightProfileUpdate');
  String get insightShareTips => _lookup('insightShareTips');
  String get insightNewPost => _lookup('insightNewPost');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
