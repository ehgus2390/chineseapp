import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const languageOptions = [
    {'code': 'ko', 'label': 'Korean'},
    {'code': 'fil', 'label': 'Filipino'},
    {'code': 'vi', 'label': 'Vietnamese'},
    {'code': 'th', 'label': 'Thai'},
    {'code': 'bn', 'label': 'Bangladeshi'},
    {'code': 'hi', 'label': 'Indian'},
    {'code': 'zh', 'label': 'Chinese'},
    {'code': 'ja', 'label': 'Japanese'},
    {'code': 'en', 'label': 'English'},
  ];

  static const nationalityOptions = [
    {'code': 'KR', 'label': 'Korea'},
    {'code': 'PH', 'label': 'Philippines'},
    {'code': 'VN', 'label': 'Vietnam'},
    {'code': 'TH', 'label': 'Thailand'},
    {'code': 'BD', 'label': 'Bangladesh'},
    {'code': 'IN', 'label': 'India'},
    {'code': 'CN', 'label': 'China'},
    {'code': 'JP', 'label': 'Japan'},
    {'code': 'US', 'label': 'English-speaking'},
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
        final lang = (data['lang'] as String?) ?? 'ko';
        final shareLocation = data['shareLocation'] != false;
        final preferredCountries =
        List<String>.from(data['preferredCountries'] ?? []);

        return Scaffold(
          appBar: AppBar(title: const Text('설정')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '언어 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: lang,
                decoration:
                const InputDecoration(border: OutlineInputBorder()),
                items: languageOptions
                    .map(
                      (lang) => DropdownMenuItem(
                    value: lang['code']!,
                    child: Text(lang['label']!),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    auth.updateProfile(lang: value);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '원하는 국적의 친구',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
