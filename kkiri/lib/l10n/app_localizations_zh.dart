// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Kkiri';

  @override
  String get welcome => '欢迎使用 Kkiri';

  @override
  String get startAnonymous => '匿名开始';

  @override
  String get emailLogin => '使用邮箱登录';

  @override
  String get profile => '个人资料';

  @override
  String get settings => '设置';

  @override
  String get report => '举报';

  @override
  String get block => '屏蔽';

  @override
  String get post => '发布';

  @override
  String get comment => '评论';

  @override
  String get like => '点赞';

  @override
  String get anonymous => '匿名';

  @override
  String get save => '保存';

  @override
  String get logout => '退出登录';

  @override
  String get language => '语言';

  @override
  String get shareLocation => '共享位置';

  @override
  String get shareLocationDesc => '用于附近朋友推荐';
}
