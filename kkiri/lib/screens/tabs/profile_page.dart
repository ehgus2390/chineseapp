import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/storage_service.dart';

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
        displayName: _displayNameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        bio: _bioController.text.trim(),
        interests: _interests,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ───────────────── ⚙️ 설정 메뉴 ─────────────────
  void _openSettingsSheet(BuildContext context, String myUid) {
    final t = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report),
                title: Text(t.report),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('reports').add({
                    'type': 'profile',
                    'reporterUid': myUid,
                    'targetUid': myUid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(t.block),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(myUid)
                      .collection('blocked')
                      .doc(myUid)
                      .set({'createdAt': FieldValue.serverTimestamp()});
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(t.language),
                onTap: () {
                  Navigator.pop(context);
                  _openLanguageSheet(context, localeProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────── 🌍 언어 설정 ─────────────
  void _openLanguageSheet(
      BuildContext context, LocaleProvider localeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: const [
              _LangItem('ko', '한국어'),
              _LangItem('en', 'English'),
              _LangItem('ja', '日本語'),
              _LangItem('zh', '中文'),
              _LangItem('vi', 'Tiếng Việt'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = AppLocalizations.of(context)!;
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (!_initialized && data != null) {
          _initialized = true;
          _displayNameController.text = data['displayName'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _gender = data['gender'];
          _bioController.text = data['bio'] ?? '';
          _interests = List<String>.from(data['interests'] ?? []);
        }

        final photoUrl = _pickedImage != null ? null : data?['photoUrl'];

        return Scaffold(
          appBar: AppBar(
            title: Text(t.profile),
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
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: '닉네임'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: '나이'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('남')),
                    DropdownMenuItem(value: 'female', child: Text('여')),
                    DropdownMenuItem(value: 'other', child: Text('기타')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                  decoration: const InputDecoration(labelText: '성별'),
                ),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '내 소개'),
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
                          v ? _interests.add(e) : _interests.remove(e);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _saveProfile(auth, uid, data),
                  icon: _saving
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.save),
                  label: Text(t.save),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LangItem extends StatelessWidget {
  final String code;
  final String label;
  const _LangItem(this.code, this.label);

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();

    return ListTile(
      title: Text(label),
      onTap: () {
        localeProvider.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }
}
