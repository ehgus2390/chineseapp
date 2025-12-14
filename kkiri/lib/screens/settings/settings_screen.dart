// lib/screens/settings/settings_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() ?? {};
        final shareLocation = data['shareLocation'] as bool? ?? true;

        return Scaffold(
          appBar: AppBar(title: const Text('설정')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 🌍 Language
              Text(
                '언어 설정',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Locale>(
                value: localeProvider.locale,
                items: languageOptions
                    .map(
                      (lang) => DropdownMenuItem(
                    value: Locale(lang['code']!),
                    child: Text(lang['label']!),
                  ),
                )
                    .toList(),
                onChanged: (locale) async {
                  if (locale == null) return;
                  localeProvider.setLocale(locale);
                  await auth.updateProfile(lang: locale.languageCode);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              /// 📍 Location
              SwitchListTile(
                title: const Text('위치 공유 허용'),
                subtitle: const Text('근처 친구 추천에 사용됩니다'),
                value: shareLocation,
                onChanged: (value) async {
                  await auth.updateProfile(shareLocation: value);

                  final loc = context.read<LocationProvider>();
                  if (value) {
                    await loc.startAutoUpdate(uid);
                  } else {
                    await loc.stopAutoUpdate();
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
