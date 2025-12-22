import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'language_setting_screen.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const languageOptions = [
    {'code': 'ko', 'label': '한국어'},
    {'code': 'en', 'label': 'English'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'vi', 'label': 'Tiếng Việt'},
    {'code': 'th', 'label': 'ภาษาไทย'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'bn', 'label': 'বাংলা'},
    {'code': 'fil', 'label': 'Filipino'},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final t = AppLocalizations.of(context);
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() ?? {};

        // ✅ shareLocation 필드가 없거나 타입이 꼬였을 때도 안전하게 처리
        final shareLocation = (data['shareLocation'] is bool)
            ? data['shareLocation'] as bool
            : true;

        return Scaffold(
          appBar: AppBar(title: Text(t.settings)),
          // appBar: AppBar(title: const Text('설정')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 🌍 Language
              Text(
                t.language,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // Text(
              //   '언어 설정',
              //   style: Theme.of(context).textTheme.titleLarge,
              // ),
              const SizedBox(height: 8),

              DropdownButtonFormField<Locale>(
                initialValue: localeProvider.locale,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: languageOptions
                    .map(
                      (lang) => DropdownMenuItem<Locale>(
                        value: Locale(lang['code']!),
                        child: Text(lang['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (locale) async {
                  if (locale == null) return;
                  localeProvider.setLocale(locale);
                },
              ),

              const SizedBox(height: 24),

              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('프로필 언어'),
                subtitle: const Text('사용 언어 / 대표 언어 설정'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSettingScreen(),
                    ),
                  );
                },
              ),

              /// 📍 Location
              SwitchListTile(
                title: Text(t.shareLocation),
                subtitle: Text(t.shareLocationDesc),
                // title: const Text('위치 공유 허용'),
                // subtitle: const Text('근처 친구 추천에 사용됩니다'),
                value: shareLocation,
                onChanged: (value) async {
                  // ✅ AuthProvider.updateProfile에 shareLocation 파라미터가 있어야 함
                  await auth.updateProfile(shareLocation: value);

                  // ✅ LocationProvider 메서드명이 프로젝트마다 다를 수 있어 try/catch로 안전 처리
                  final loc = context.read<LocationProvider>();
                  try {
                    if (value) {
                      // 네 프로젝트에 startAutoUpdate(uid) 가 존재할 때
                      await loc.startAutoUpdate(uid);
                    } else {
                      // 네 프로젝트에 stopAutoUpdate() 가 존재할 때
                      await loc.stopAutoUpdate();
                    }
                  } catch (e) {
                    // 메서드명이 다르거나 구현이 없으면 여기로 옴
                    // -> 이 경우 LocationProvider 쪽 함수명/구현을 맞춰야 함
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('위치 업데이트 처리 중 오류: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
