import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
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
  final _upgradeEmailController = TextEditingController();
  final _upgradePasswordController = TextEditingController();

  final List<String> _interestOptions = const [
    'K-pop',
    'Travel',
    'Food',
    'Language exchange',
    'Gaming',
    'Study buddy',
  ];

  String? _gender;
  List<String> _interests = [];
  bool _initialised = false;

  File? _pickedImage;
  bool _saving = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _upgradeEmailController.dispose();
    _upgradePasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return null;
    final storage = StorageService();
    return storage.uploadProfileImage(uid: uid, file: _pickedImage!);
  }

  Future<void> _saveProfile(AuthProvider auth, String uid, Map<String, dynamic>? data) async {
    setState(() => _saving = true);
    try {
      final url = await _uploadPhoto(uid) ?? (data?['photoUrl'] as String?);
      await auth.updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        photoUrl: url,
        age: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        interests: _interests,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (!_initialised && data != null) {
          _initialised = true;
          _displayNameController.text = (data['displayName'] as String?) ?? '';
          final age = data['age'];
          if (age != null) _ageController.text = age.toString();
          _gender = data['gender'] as String?;
          _bioController.text = (data['bio'] as String?) ?? '';
          _interests = List<String>.from(data['interests'] ?? []);
        }

        final photoUrl = _pickedImage != null
            ? null
            : (data?['photoUrl'] as String? ?? auth.currentUser?.photoURL);

        return Scaffold(
          appBar: AppBar(
            title: const Text('내 프로필'),
            actions: [
              IconButton(
                onPressed: () async {
                  await auth.sendEmailVerification(); // ✅ 이제 AuthProvider에 존재
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('인증 메일을 보냈습니다. 메일함을 확인하세요.')),
                  );
                },
                icon: const Icon(Icons.mark_email_unread_outlined),
                tooltip: '인증 메일 보내기',
              ),
              IconButton(
                onPressed: () async {
                  await auth.reloadUser();
                },
                icon: const Icon(Icons.refresh),
                tooltip: '인증 상태 새로고침',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (photoUrl != null
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/logo.png')
                        as ImageProvider),
                      ),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('사진 변경'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      auth.isEmailVerified ? Icons.verified : Icons.error_outline,
                      color: auth.isEmailVerified ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.isEmailVerified
                            ? '이메일 인증 완료 - 1:1 기능 사용 가능'
                            : '이메일 인증이 필요합니다. 인증 메일을 확인해주세요.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: '닉네임'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '나이'),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: '내 소개'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('관심사'),
                Wrap(
                  spacing: 8,
                  children: _interestOptions.map((interest) {
                    final selected = _interests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _interests = [..._interests, interest];
                          } else {
                            _interests = _interests.where((e) => e != interest).toList();
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saving ? null : () => _saveProfile(auth, uid, data),
                  icon: _saving
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save),
                  label: const Text('저장'),
                ),
                const Divider(height: 32),
                Text('이메일 계정 업그레이드', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _upgradeEmailController,
                  decoration: const InputDecoration(labelText: '이메일'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _upgradePasswordController,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final email = _upgradeEmailController.text.trim();
                    final password = _upgradePasswordController.text.trim();
                    if (email.isEmpty || password.isEmpty) return;

                    try {
                      await auth.upgradeToEmailAccount(email, password);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('업그레이드 완료! 인증 메일을 확인하세요.'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('업그레이드 실패: $e')),
                      );
                    }
                  },
                  child: const Text('업그레이드'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
