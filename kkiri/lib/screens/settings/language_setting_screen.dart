import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LanguageSettingScreen extends StatefulWidget {
  const LanguageSettingScreen({super.key});

  @override
  State<LanguageSettingScreen> createState() => _LanguageSettingScreenState();
}

class _LanguageSettingScreenState extends State<LanguageSettingScreen> {
  static const supportedLanguages = [
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

  List<String> _languages = [];
  String? _mainLanguage;
  bool _isSaving = false;
  bool _initialized = false;

  void _toggle(String code, bool selected) {
    setState(() {
      if (selected) {
        if (!_languages.contains(code)) _languages.add(code);
        _mainLanguage ??= code;
      } else {
        _languages.remove(code);
        if (_mainLanguage == code) {
          _mainLanguage = _languages.isNotEmpty ? _languages.first : null;
        }
      }
    });
  }

  Future<void> _save(AuthProvider auth) async {
    if (_languages.isEmpty || _mainLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개의 언어와 대표 언어를 선택하세요')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await auth.updateProfile(
      languages: _languages,
      mainLanguage: _mainLanguage,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
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
        final serverLanguages =
        List<String>.from(data['languages'] ?? const <String>[]);
        final serverMain = data['mainLanguage'] as String?;

        // 최초 1회만 서버 값으로 로컬 상태 초기화
        if (!_initialized) {
          _languages = serverLanguages.isNotEmpty ? serverLanguages : ['ko'];
          _mainLanguage = serverMain ?? _languages.first;
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('프로필 언어 설정'),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => _save(auth),
                child: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('저장'),
              ),
            ],
          ),
          body: ListView(
            children: supportedLanguages.map((lang) {
              final code = lang['code']!;
              final label = lang['label']!;
              final selected = _languages.contains(code);

              return CheckboxListTile(
                title: Text(label),
                value: selected,
                onChanged: (v) => _toggle(code, v ?? false),
                secondary: Radio<String>(
                  value: code,
                  groupValue: _mainLanguage,
                  onChanged: selected
                      ? (v) => setState(() => _mainLanguage = v)
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
