import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/community_profile_repository.dart';
import '../state/app_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final _repository = CommunityProfileRepository();

  static const _nationalityOptions = <String>[
    'Korea',
    'Japan',
    'China',
    'Vietnam',
    'Thailand',
    'India',
    'Bangladesh',
    'Philippines',
    'Other',
  ];

  static const _languageOptions = <String>[
    'ko',
    'en',
    'ja',
    'zh',
    'vi',
    'th',
    'hi',
    'bn',
    'fil',
  ];

  String? _nationality;
  final Set<String> _languages = <String>{};
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialValues() async {
    final uid = context.read<AppState>().user?.uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final data = await _repository.getProfileData(uid);
    if (!mounted) return;

    final nickname = data?['nickname'];
    final nationality = data?['nationality'];
    final languages = data?['languages'];

    _nicknameController.text = nickname is String ? nickname : '';
    _nationality =
        nationality is String && nationality.isNotEmpty ? nationality : null;
    if (languages is List) {
      for (final item in languages) {
        if (item is String && item.isNotEmpty) {
          _languages.add(item);
        }
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = context.read<AppState>().user?.uid;
    final nickname = _nicknameController.text.trim();
    final nationality = _nationality;

    if (uid == null || uid.isEmpty) return;
    if (nickname.isEmpty || nationality == null || _languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.updateSetupFields(
        uid: uid,
        nickname: nickname,
        nationality: nationality,
        languages: _languages.toList(),
      );
      await context.read<AppState>().refreshCommunityProfileStatus();

      if (!mounted) return;
      context.go('/home/home');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete your profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nicknameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nickname *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _nationality,
            items: _nationalityOptions
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _nationality = value),
            decoration: const InputDecoration(
              labelText: 'Nationality *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Languages *',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languageOptions
                .map(
                  (lang) => FilterChip(
                    label: Text(lang),
                    selected: _languages.contains(lang),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _languages.add(lang);
                        } else {
                          _languages.remove(lang);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
