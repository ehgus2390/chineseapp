import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProv = context.watch<LocaleProvider>();
    return ListView(
      children: [
        ListTile(
          title: const Text('언어 설정'),
          trailing: DropdownButton<Locale>(
            value: localeProv.locale,
            items: const [
              DropdownMenuItem(value: Locale('ko'), child: Text('한국어')),
              DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
              DropdownMenuItem(value: Locale('hi'), child: Text('हिंदी')),
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(value: Locale('ja'), child: Text('日本語')),
            ],
            onChanged: (loc) => localeProv.setLocale(loc!),
          ),
        ),
        const Divider(),
        const ListTile(title: Text('알림 설정'), subtitle: Text('푸시 알림(추후 FCM 연동)')),
        const ListTile(title: Text('고객센터'), subtitle: Text('support@kkiri.app')),
      ],
    );
  }
}
