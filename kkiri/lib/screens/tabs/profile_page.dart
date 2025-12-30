import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/auth_guard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();

  final _interestOptions = const [
    'K-pop',
    'Travel',
    'Food',
    'Language exchange',
    'Gaming',
    'Study buddy',
  ];

  String? _gender;
  List<String> _interests = [];
  bool _initialized = false;
  File? _pickedImage;
  bool _saving = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return null;
    return StorageService().uploadProfileImage(uid: uid, file: _pickedImage!);
  }

  Future<void> _saveProfile(
    AuthProvider auth,
    String uid,
    Map<String, dynamic>? data,
  ) async {
    setState(() => _saving = true);
    try {
      final photoUrl = await _uploadPhoto(uid) ?? data?['photoUrl'];

      await auth.updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        interests: _interests,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t?.save ?? 'Save')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openSettingsSheet(BuildContext context, String myUid) {
    final t = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ???�어?�정
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(t?.language ?? 'Language'),
                onTap: () {
                  Navigator.pop(context);
                  _openLanguageSheet(context, myUid);
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: Text(t?.report ?? 'Report'),
                subtitle: const Text(''),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: Text(t?.block ?? 'Block'),
                subtitle: const Text(''),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ?�?�?�?�?�?�?�?�?�?�?�?�?� ?�� ?�어 ?�정 (즉시 반영 + Firestore lang ?�?? ?�?�?�?�?�?�?�?�?�?�?�?�?�
  void _openLanguageSheet(BuildContext context, String myUid) {
    final auth = context.read<AuthProvider>();
    final localeProvider = context.read<LocaleProvider>();

    Future<void> setLang(String code) async {
      // 1) ??즉시 반영
      localeProvider.setLocale(Locale(code));

      // 2) Firestore ?�??(users/{uid}.lang)
      await auth.updateProfile(languages: [code], mainLanguage: code);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('언어가 변경되었습니다: $code')),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: const Text('한국어'), onTap: () => setLang('ko')),
              ListTile(
                  title: const Text('English'), onTap: () => setLang('en')),
              ListTile(title: const Text('日本語'), onTap: () => setLang('ja')),
              ListTile(
                  title: const Text('中文'),
                  onTap: () => setLang('zh')), // ?요?면 ?기 계속 추? 가??
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = AppLocalizations.of(context);
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Login required to use profile features',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (!_initialized && data != null) {
          _initialized = true;
          _displayNameController.text = (data['displayName'] ?? '') as String;
          _ageController.text = data['age']?.toString() ?? '';
          _gender = data['gender'] as String?;
          _bioController.text = (data['bio'] ?? '') as String;
          _interests = List<String>.from(data['interests'] ?? []);
        }

        final photoUrl = _pickedImage != null ? null : data?['photoUrl'];

        return Scaffold(
          appBar: AppBar(
            title: Text(t?.profile ?? 'Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _openSettingsSheet(context, uid),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (photoUrl != null
                              ? NetworkImage(photoUrl)
                              : const AssetImage('assets/images/logo.png'))
                          as ImageProvider,
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('사진 변경'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: '이름'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: '나이'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('남성')),
                    DropdownMenuItem(value: 'female', child: Text('여성')),
                    DropdownMenuItem(value: 'other', child: Text('기타')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                  decoration: const InputDecoration(labelText: '성별'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '자기소개'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: _interestOptions.map((e) {
                    final selected = _interests.contains(e);
                    return FilterChip(
                      label: Text(e),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            if (!_interests.contains(e)) _interests.add(e);
                          } else {
                            _interests.remove(e);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!await requireEmailLogin(
                              context, t?.profile ?? 'Profile')) {
                            return;
                          }
                          await _saveProfile(auth, uid, data);
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(t?.save ?? 'Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
