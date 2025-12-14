import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const languageOptions = [
    {'code': 'ko', 'label': '한국어'},
    {'code': 'fil', 'label': 'Filipino'},
    {'code': 'vi', 'label': 'Tiếng Việt'},
    {'code': 'th', 'label': 'ภาษาไทย'},
    {'code': 'bn', 'label': 'বাংলা'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'en', 'label': 'English'},
  ];

  static const nationalityOptions = [
    {'code': 'KR', 'label': '한국'},
    {'code': 'PH', 'label': '필리핀'},
    {'code': 'VN', 'label': '베트남'},
    {'code': 'TH', 'label': '태국'},
    {'code': 'BD', 'label': '방글라데시'},
    {'code': 'IN', 'label': '인도'},
    {'code': 'CN', 'label': '중국'},
    {'code': 'JP', 'label': '일본'},
    {'code': 'US', 'label': '미국'},
  ];

  Future<void> _togglePreferredCountry(
      AuthProvider auth,
      List<String> current,
      String code,
      ) async {
    final updated = List<String>.from(current);
    if (updated.contains(code)) {
      updated.remove(code);
    } else {
      updated.add(code);
    }
    await auth.updateProfile(preferredCountries: updated);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }

    final userDocStream =
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!.data() ?? {};
        final shareLocation = data['shareLocation'] != false;
        final preferredCountries =
        List<String>.from(data['preferredCountries'] ?? []);

        return Scaffold(
          appBar: AppBar(title: const Text('설정')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '언어 설정',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Locale>(
                value: localeProvider.locale,
                decoration:
                const InputDecoration(border: OutlineInputBorder()),
                items: languageOptions
                    .map(
                      (lang) => DropdownMenuItem(
                    value: Locale(lang['code']!),
                    child: Text(lang['label']!),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    localeProvider.setLocale(value);
                    auth.updateProfile(lang: value.languageCode);
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                '원하는 국적의 친구',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in nationalityOptions)
                    FilterChip(
                      label: Text(option['label']!),
                      selected:
                      preferredCountries.contains(option['code']!),
                      onSelected: (_) => _togglePreferredCountry(
                        auth,
                        preferredCountries,
                        option['code']!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('위치 공유 허용'),
                subtitle:
                const Text('지도를 통한 추천 친구 표시를 위해 사용됩니다.'),
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
