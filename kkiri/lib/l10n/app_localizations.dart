import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return result ?? AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('es'),
  ];

  String get appName => _string('appName');
  String get signInTitle => _string('signInTitle');
  String get signInSubtitle => _string('signInSubtitle');
  String get signInCta => _string('signInCta');
  String get chatTab => _string('chatTab');
  String get discoverTab => _string('discoverTab');
  String get mapTab => _string('mapTab');
  String get matchesTab => _string('matchesTab');
  String get profileTab => _string('profileTab');
  String get chatListTitle => _string('chatListTitle');
  String get recommendedNearbyTitle => _string('recommendedNearbyTitle');
  String get recommendedNearbySubtitle => _string('recommendedNearbySubtitle');
  String get recommendedEmpty => _string('recommendedEmpty');
  String get recommendedStartChat => _string('recommendedStartChat');
  String get chatEmptyState => _string('chatEmptyState');
  String get discoverTitle => _string('discoverTitle');
  String get openMap => _string('openMap');
  String get noCandidates => _string('noCandidates');
  String get retry => _string('retry');
  String get radiusLabel => _string('radiusLabel');
  String get interestFilterLabel => _string('interestFilterLabel');
  String get passButton => _string('passButton');
  String get likeButton => _string('likeButton');
  String get matchesTitle => _string('matchesTitle');
  String get matchesEmpty => _string('matchesEmpty');
  String get profileTitle => _string('profileTitle');
  String get nameLabel => _string('nameLabel');
  String get bioLabel => _string('bioLabel');
  String get bioHint => _string('bioHint');
  String get ageLabel => _string('ageLabel');
  String get genderLabel => _string('genderLabel');
  String get interestLabel => _string('interestLabel');
  String get interestsHelp => _string('interestsHelp');
  String get customInterestLabel => _string('customInterestLabel');
  String get customInterestHint => _string('customInterestHint');
  String get addCustomInterest => _string('addCustomInterest');
  String get saveProfile => _string('saveProfile');
  String get saving => _string('saving');
  String get logout => _string('logout');
  String get settingsTitle => _string('settingsTitle');
  String get languageSectionTitle => _string('languageSectionTitle');
  String get languageSectionSubtitle => _string('languageSectionSubtitle');
  String get languageUpdated => _string('languageUpdated');
  String get chatHint => _string('chatHint');
  String get mapTitle => _string('mapTitle');
  String get searchRadius => _string('searchRadius');
  String get recDistanceTag => _string('recDistanceTag');
  String get myProfileUpdated => _string('myProfileUpdated');
  String get profileUpdateError => _string('profileUpdateError');
  String get newMatchSnack => _string('newMatchSnack');
  String get likeSentSnack => _string('likeSentSnack');
  String get pleaseShareLocation => _string('pleaseShareLocation');
  String get recenter => _string('recenter');

  String radiusDisplay(double km) => _string('radiusDisplay').replaceFirst('{km}', km.toStringAsFixed(0));

  String genderName(String value) {
    switch (value) {
      case 'female':
        return _string('genderFemale');
      case 'male':
        return _string('genderMale');
      case 'nonbinary':
        return _string('genderNonbinary');
      case 'prefer_not':
        return _string('genderPreferNot');
      default:
        return _string('genderPreferNot');
    }
  }

  String interestLabelText(String id) {
    final map = _interestLabels[locale.languageCode] ?? _interestLabels['en']!;
    return map[id] ?? id;
  }

  String languageName(String code) {
    final map = _languageNames[locale.languageCode] ?? _languageNames['en']!;
    return map[code] ?? map['en']!;
  }

  String _string(String key) {
    final map = _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
    return map[key] ?? _localizedValues['en']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'LinguaCircle',
      'signInTitle': 'Welcome to LinguaCircle',
      'signInSubtitle': 'Meet nearby friends within 5km, share hobbies, and start chatting instantly.',
      'signInCta': 'Start chatting anonymously',
      'chatTab': 'Chat',
      'discoverTab': 'Discover',
      'mapTab': 'Map',
      'matchesTab': 'Matches',
      'profileTab': 'Profile',
      'chatListTitle': 'Conversations',
      'recommendedNearbyTitle': 'Within 5km',
      'recommendedNearbySubtitle': 'People who share your hobbies',
      'recommendedEmpty': 'Turn on location services to see nearby friends.',
      'recommendedStartChat': 'Say hi',
      'chatEmptyState': 'No conversations yet. Start with a friendly hello!',
      'discoverTitle': 'Find nearby friends',
      'openMap': 'View map',
      'noCandidates': 'No new recommendations in this radius. Try widening the range or updating your hobbies.',
      'retry': 'Try again',
      'radiusLabel': 'Radius',
      'interestFilterLabel': 'Filter by hobby',
      'passButton': 'Skip',
      'likeButton': 'Like',
      'matchesTitle': 'Your matches',
      'matchesEmpty': 'You have no matches yet. Send a like to start a conversation.',
      'profileTitle': 'My profile',
      'nameLabel': 'Name',
      'bioLabel': 'Bio',
      'bioHint': 'Share a warm introduction',
      'ageLabel': 'Age',
      'genderLabel': 'Gender',
      'interestLabel': 'Hobbies & interests',
      'interestsHelp': 'Select all that describe you',
      'customInterestLabel': 'Other interests',
      'customInterestHint': 'Add your own tag',
      'addCustomInterest': 'Add',
      'saveProfile': 'Save profile',
      'saving': 'Saving...',
      'logout': 'Sign out',
      'settingsTitle': 'Settings',
      'languageSectionTitle': 'Languages',
      'languageSectionSubtitle': 'Pick the language you are most comfortable with',
      'languageUpdated': 'Language updated',
      'chatHint': 'Type a message...',
      'mapTitle': 'Nearby map',
      'searchRadius': 'Radius',
      'recDistanceTag': 'Recommended 5km',
      'recenter': 'Recenter',
      'myProfileUpdated': 'Profile updated',
      'profileUpdateError': 'Could not save your profile. Try again.',
      'newMatchSnack': 'It\'s a match! You can start chatting now.',
      'likeSentSnack': 'Sent a like. We\'ll let you know when it\'s mutual.',
      'pleaseShareLocation': 'Share your location to unlock recommendations.',
      'genderFemale': 'Female',
      'genderMale': 'Male',
      'genderNonbinary': 'Non-binary',
      'genderPreferNot': 'Prefer not to say',
      'radiusDisplay': '{km} km',
    },
    'ko': {
      'appName': 'LinguaCircle',
      'signInTitle': '링구어서클에 오신 것을 환영해요',
      'signInSubtitle': '반경 5km 안의 친구들과 취미를 나누고 편안하게 대화를 시작해보세요.',
      'signInCta': '익명으로 바로 시작하기',
      'chatTab': '채팅',
      'discoverTab': '발견',
      'mapTab': '지도',
      'matchesTab': '매칭',
      'profileTab': '프로필',
      'chatListTitle': '대화 목록',
      'recommendedNearbyTitle': '5km 추천',
      'recommendedNearbySubtitle': '취미가 통하는 친구들',
      'recommendedEmpty': '주변 추천을 보려면 위치 서비스를 켜주세요.',
      'recommendedStartChat': '인사하기',
      'chatEmptyState': '아직 대화가 없어요. 먼저 따뜻하게 인사해보세요!',
      'discoverTitle': '근처 친구 찾기',
      'openMap': '지도 보기',
      'noCandidates': '이 반경 안에는 새로운 추천이 없어요. 반경을 넓히거나 관심사를 업데이트해보세요.',
      'retry': '다시 시도',
      'radiusLabel': '검색 반경',
      'interestFilterLabel': '관심사 필터',
      'passButton': '패스',
      'likeButton': '좋아요',
      'matchesTitle': '내 매칭',
      'matchesEmpty': '아직 매칭된 사람이 없어요. 발견 탭에서 좋아요를 보내보세요.',
      'profileTitle': '내 프로필',
      'nameLabel': '이름',
      'bioLabel': '소개',
      'bioHint': '편안한 소개를 남겨보세요',
      'ageLabel': '나이',
      'genderLabel': '성별',
      'interestLabel': '취미와 관심사',
      'interestsHelp': '나를 잘 나타내는 항목을 선택하세요',
      'customInterestLabel': '기타 관심사',
      'customInterestHint': '직접 태그를 추가하세요',
      'addCustomInterest': '추가',
      'saveProfile': '프로필 저장',
      'saving': '저장 중...',
      'logout': '로그아웃',
      'settingsTitle': '설정',
      'languageSectionTitle': '언어',
      'languageSectionSubtitle': '가장 편안한 언어를 선택하세요',
      'languageUpdated': '언어가 변경되었습니다',
      'chatHint': '메시지 입력...',
      'mapTitle': '근처 지도',
      'searchRadius': '검색 반경',
      'recDistanceTag': '추천 반경 5km',
      'recenter': '내 위치로 이동',
      'myProfileUpdated': '프로필이 업데이트되었습니다.',
      'profileUpdateError': '프로필 저장에 실패했어요. 다시 시도해주세요.',
      'newMatchSnack': '새로운 매칭! 지금 바로 채팅을 시작해보세요.',
      'likeSentSnack': '좋아요를 보냈어요. 서로 마음이 통하면 알려드릴게요.',
      'pleaseShareLocation': '추천을 보려면 위치 정보를 공유해주세요.',
      'genderFemale': '여성',
      'genderMale': '남성',
      'genderNonbinary': '논바이너리',
      'genderPreferNot': '선택 안 함',
      'radiusDisplay': '{km} km',
    },
    'ja': {
      'appName': 'LinguaCircle',
      'signInTitle': 'LinguaCircle へようこそ',
      'signInSubtitle': '半径5kmの友だちと趣味を共有して、すぐにチャットを始めましょう。',
      'signInCta': '匿名ですぐ開始',
      'chatTab': 'チャット',
      'discoverTab': '発見',
      'mapTab': 'マップ',
      'matchesTab': 'マッチ',
      'profileTab': 'プロフィール',
      'chatListTitle': '会話',
      'recommendedNearbyTitle': '5km 以内',
      'recommendedNearbySubtitle': '趣味が合う人たち',
      'recommendedEmpty': '位置情報をオンにすると周辺の友だちが表示されます。',
      'recommendedStartChat': 'あいさつ',
      'chatEmptyState': 'まだ会話がありません。やさしく声をかけてみましょう。',
      'discoverTitle': '近くの友だちを探す',
      'openMap': '地図を見る',
      'noCandidates': 'この範囲には新しいおすすめがありません。範囲を広げるか趣味を更新してください。',
      'retry': '再試行',
      'radiusLabel': '検索範囲',
      'interestFilterLabel': '趣味フィルター',
      'passButton': 'スキップ',
      'likeButton': 'いいね',
      'matchesTitle': 'マッチ一覧',
      'matchesEmpty': 'まだマッチがありません。発見タブでいいねしてみましょう。',
      'profileTitle': 'マイプロフィール',
      'nameLabel': '名前',
      'bioLabel': 'ひと言紹介',
      'bioHint': '温かい自己紹介を書いてください',
      'ageLabel': '年齢',
      'genderLabel': '性別',
      'interestLabel': '趣味・関心',
      'interestsHelp': '当てはまるものを選択',
      'customInterestLabel': 'その他の興味',
      'customInterestHint': '自分のタグを追加',
      'addCustomInterest': '追加',
      'saveProfile': 'プロフィールを保存',
      'saving': '保存中...',
      'logout': 'ログアウト',
      'settingsTitle': '設定',
      'languageSectionTitle': '言語',
      'languageSectionSubtitle': '心地よい言語を選んでください',
      'languageUpdated': '言語を更新しました',
      'chatHint': 'メッセージを入力...',
      'mapTitle': '近くのマップ',
      'searchRadius': '範囲',
      'recDistanceTag': 'おすすめ 5km',
      'recenter': '現在地に戻る',
      'myProfileUpdated': 'プロフィールを更新しました。',
      'profileUpdateError': 'プロフィールを保存できませんでした。',
      'newMatchSnack': 'マッチしました！今すぐチャットできます。',
      'likeSentSnack': 'いいねを送りました。相手もいいねするとお知らせします。',
      'pleaseShareLocation': 'おすすめを見るには位置情報を共有してください。',
      'genderFemale': '女性',
      'genderMale': '男性',
      'genderNonbinary': 'ノンバイナリー',
      'genderPreferNot': '回答しない',
      'radiusDisplay': '{km} km',
    },
    'zh': {
      'appName': 'LinguaCircle',
      'signInTitle': '歡迎加入 LinguaCircle',
      'signInSubtitle': '在 5 公里內找到擁有相同興趣的朋友，立即開始聊天。',
      'signInCta': '匿名立即開始',
      'chatTab': '聊天',
      'discoverTab': '探索',
      'mapTab': '地圖',
      'matchesTab': '配對',
      'profileTab': '個人檔案',
      'chatListTitle': '對話列表',
      'recommendedNearbyTitle': '5 公里內',
      'recommendedNearbySubtitle': '與你興趣相同的人',
      'recommendedEmpty': '開啟定位服務即可看到附近的朋友。',
      'recommendedStartChat': '打聲招呼',
      'chatEmptyState': '尚無對話，先發個友善的訊息吧！',
      'discoverTitle': '尋找附近朋友',
      'openMap': '查看地圖',
      'noCandidates': '此範圍目前沒有推薦。請調整距離或更新興趣。',
      'retry': '重試',
      'radiusLabel': '搜尋範圍',
      'interestFilterLabel': '依興趣篩選',
      'passButton': '略過',
      'likeButton': '喜歡',
      'matchesTitle': '我的配對',
      'matchesEmpty': '尚未有配對。到探索頁面按下喜歡吧。',
      'profileTitle': '我的檔案',
      'nameLabel': '名稱',
      'bioLabel': '簡介',
      'bioHint': '留下溫暖的介紹',
      'ageLabel': '年齡',
      'genderLabel': '性別',
      'interestLabel': '興趣與嗜好',
      'interestsHelp': '選擇最能代表你的項目',
      'customInterestLabel': '其他興趣',
      'customInterestHint': '新增自訂標籤',
      'addCustomInterest': '新增',
      'saveProfile': '儲存檔案',
      'saving': '儲存中...',
      'logout': '登出',
      'settingsTitle': '設定',
      'languageSectionTitle': '語言',
      'languageSectionSubtitle': '選擇最舒服的語言',
      'languageUpdated': '語言已更新',
      'chatHint': '輸入訊息...',
      'mapTitle': '附近地圖',
      'searchRadius': '距離',
      'recDistanceTag': '建議 5 公里',
      'recenter': '回到目前位置',
      'myProfileUpdated': '已更新個人檔案。',
      'profileUpdateError': '無法儲存，請再試一次。',
      'newMatchSnack': '配對成功！現在就開始聊天吧。',
      'likeSentSnack': '已送出喜歡。互相喜歡時會通知你。',
      'pleaseShareLocation': '請分享位置以取得推薦。',
      'genderFemale': '女性',
      'genderMale': '男性',
      'genderNonbinary': '非二元',
      'genderPreferNot': '不透露',
      'radiusDisplay': '{km} 公里',
    },
    'es': {
      'appName': 'LinguaCircle',
      'signInTitle': 'Bienvenido a LinguaCircle',
      'signInSubtitle': 'Conoce amigos a 5 km, comparte tus hobbies y chatea al instante.',
      'signInCta': 'Comenzar de forma anónima',
      'chatTab': 'Chat',
      'discoverTab': 'Descubre',
      'mapTab': 'Mapa',
      'matchesTab': 'Matches',
      'profileTab': 'Perfil',
      'chatListTitle': 'Conversaciones',
      'recommendedNearbyTitle': 'A 5 km',
      'recommendedNearbySubtitle': 'Personas con tus intereses',
      'recommendedEmpty': 'Activa la ubicación para ver amigos cercanos.',
      'recommendedStartChat': 'Saludar',
      'chatEmptyState': 'Aún no hay conversaciones. Envía un saludo amable.',
      'discoverTitle': 'Encuentra amigos cercanos',
      'openMap': 'Ver mapa',
      'noCandidates': 'No hay nuevas recomendaciones. Amplía el radio o actualiza tus hobbies.',
      'retry': 'Reintentar',
      'radiusLabel': 'Radio',
      'interestFilterLabel': 'Filtrar por hobby',
      'passButton': 'Omitir',
      'likeButton': 'Me gusta',
      'matchesTitle': 'Tus matches',
      'matchesEmpty': 'Todavía no tienes matches. Envía un “me gusta”.',
      'profileTitle': 'Mi perfil',
      'nameLabel': 'Nombre',
      'bioLabel': 'Presentación',
      'bioHint': 'Comparte una introducción cálida',
      'ageLabel': 'Edad',
      'genderLabel': 'Género',
      'interestLabel': 'Hobbies e intereses',
      'interestsHelp': 'Selecciona los que te describen',
      'customInterestLabel': 'Otros intereses',
      'customInterestHint': 'Añade tu propia etiqueta',
      'addCustomInterest': 'Agregar',
      'saveProfile': 'Guardar perfil',
      'saving': 'Guardando...',
      'logout': 'Cerrar sesión',
      'settingsTitle': 'Configuraciones',
      'languageSectionTitle': 'Idiomas',
      'languageSectionSubtitle': 'Elige el idioma más cómodo para ti',
      'languageUpdated': 'Idioma actualizado',
      'chatHint': 'Escribe un mensaje...',
      'mapTitle': 'Mapa cercano',
      'searchRadius': 'Radio',
      'recDistanceTag': 'Recomendado 5 km',
      'recenter': 'Centrar en mí',
      'myProfileUpdated': 'Perfil actualizado.',
      'profileUpdateError': 'No pudimos guardar el perfil. Intenta de nuevo.',
      'newMatchSnack': '¡Es un match! Ya puedes chatear.',
      'likeSentSnack': 'Enviamos tu “me gusta”. Te avisaremos si es mutuo.',
      'pleaseShareLocation': 'Comparte tu ubicación para ver recomendaciones.',
      'genderFemale': 'Mujer',
      'genderMale': 'Hombre',
      'genderNonbinary': 'No binario',
      'genderPreferNot': 'Prefiero no decirlo',
      'radiusDisplay': '{km} km',
    },
  };

  static const Map<String, Map<String, String>> _interestLabels = {
    'en': {
      'coffee': 'Cafe hopping',
      'travel': 'Travel',
      'hiking': 'Hiking',
      'music': 'Music',
      'gaming': 'Gaming',
      'art': 'Art & design',
      'foodie': 'Foodie',
      'language': 'Language exchange',
      'kdrama': 'K-Drama & films',
      'fitness': 'Fitness & wellness',
    },
    'ko': {
      'coffee': '카페 탐방',
      'travel': '여행',
      'hiking': '등산/트레킹',
      'music': '음악 감상',
      'gaming': '게임',
      'art': '예술/디자인',
      'foodie': '맛집 탐방',
      'language': '언어 교환',
      'kdrama': 'K-드라마·영화',
      'fitness': '운동·웰니스',
    },
    'ja': {
      'coffee': 'カフェ巡り',
      'travel': '旅行',
      'hiking': 'ハイキング',
      'music': '音楽',
      'gaming': 'ゲーム',
      'art': 'アート/デザイン',
      'foodie': 'グルメ探索',
      'language': '言語交換',
      'kdrama': '韓国ドラマ・映画',
      'fitness': 'フィットネス',
    },
    'zh': {
      'coffee': '咖啡探店',
      'travel': '旅行',
      'hiking': '健行',
      'music': '音樂',
      'gaming': '遊戲',
      'art': '藝術/設計',
      'foodie': '美食',
      'language': '語言交換',
      'kdrama': '韓劇/電影',
      'fitness': '健身/養生',
    },
    'es': {
      'coffee': 'Ruta de cafés',
      'travel': 'Viajes',
      'hiking': 'Senderismo',
      'music': 'Música',
      'gaming': 'Videojuegos',
      'art': 'Arte y diseño',
      'foodie': 'Gastronomía',
      'language': 'Intercambio de idiomas',
      'kdrama': 'K-Drama y cine',
      'fitness': 'Ejercicio y bienestar',
    },
  };

  static const Map<String, Map<String, String>> _languageNames = {
    'en': {
      'ko': 'Korean',
      'en': 'English',
      'ja': 'Japanese',
      'zh': 'Chinese',
      'es': 'Spanish',
    },
    'ko': {
      'ko': '한국어',
      'en': '영어',
      'ja': '일본어',
      'zh': '중국어',
      'es': '스페인어',
    },
    'ja': {
      'ko': '韓国語',
      'en': '英語',
      'ja': '日本語',
      'zh': '中国語',
      'es': 'スペイン語',
    },
    'zh': {
      'ko': '韓語',
      'en': '英語',
      'ja': '日語',
      'zh': '中文',
      'es': '西班牙語',
    },
    'es': {
      'ko': 'Coreano',
      'en': 'Inglés',
      'ja': 'Japonés',
      'zh': 'Chino',
      'es': 'Español',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
