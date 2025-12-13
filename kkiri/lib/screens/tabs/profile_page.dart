// lib/screens/tabs/profile_page.dart
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
  final _displayNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _upgradeEmailCtrl = TextEditingController();
  final _upgradePasswordCtrl = TextEditingController();

  final _picker = ImagePicker();
  File? _pickedImage;

  String? _gender;
  String? _country;
  List<String> _interests = [];
  bool _initialized = false;
  bool _saving = false;

  static const interestOptions = [
    'K-pop',
    'Travel',
    'Food',
    'Language exchange',
    'Gaming',
    'Study buddy',
  ];

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _ageCtrl.dispose();
    _bioCtrl.dispose();
    _upgradeEmailCtrl.dispose();
    _upgradePasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      setState(() => _pickedImage = File(x.path));
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_pickedImage == null) return null;
    return StorageService().uploadProfileImage(uid: uid, file: _pickedImage!);
  }

  Future<void> _saveProfile(AuthProvider auth, String uid, Map<String, dynamic>? data) async {
    setState(() => _saving = true);
    try {
      final photoUrl = await _uploadImage(uid) ?? data?['photoUrl'];
      await auth.updateProfile(
        displayName: _displayNameCtrl.text.trim().isEmpty
            ? null
            : _displayNameCtrl.text.trim(),
        photoUrl: photoUrl,
        age: int.tryParse(_ageCtrl.text),
        gender: _gender,
        country: _country,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        interests: _interests,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다')),
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
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (!_initialized && data != null) {
          _initialized = true;
          _displayNameCtrl.text = data['displayName'] ?? '';
          _ageCtrl.text = data['age']?.toString() ?? '';
          _bioCtrl.text = data['bio'] ?? '';
          _gender = data['gender'];
          _country = data['country'];
          _interests = List<String>.from(data['interests'] ?? []);
        }

        final photoUrl = _pickedImage != null
            ? null
            : data?['photoUrl'] ?? auth.currentUser?.photoURL;

        return Scaffold(
          appBar: AppBar(
            title: const Text('내 프로필'),
            actions: [
              IconButton(
                icon: Icon(
                  auth.isEmailVerified ? Icons.verified : Icons.mark_email_unread_outlined,
                  color: auth.isEmailVerified ? Colors.green : Colors.orange,
                ),
                onPressed: auth.isEmailVerified
                    ? null
                    : () => auth.sendEmailVerification(),
                tooltip: '이메일 인증',
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
                      : const AssetImage('assets/images/logo.png')
                  as ImageProvider),
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('사진 변경'),
                ),

                TextField(
                  controller: _displayNameCtrl,
                  decoration: const InputDecoration(labelText: '닉네임'),
                ),
                TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '나이'),
                ),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: '성별'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('남')),
                    DropdownMenuItem(value: 'female', child: Text('여')),
                    DropdownMenuItem(value: 'other', child: Text('기타')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(labelText: '국적'),
                  items: const [
                    DropdownMenuItem(value: 'KR', child: Text('대한민국')),
                    DropdownMenuItem(value: 'JP', child: Text('일본')),
                  ],
                  onChanged: (v) => setState(() => _country = v),
                ),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '자기소개'),
                ),

                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('관심사')),
                Wrap(
                  spacing: 8,
                  children: interestOptions.map((i) {
                    final selected = _interests.contains(i);
                    return FilterChip(
                      label: Text(i),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          v ? _interests.add(i) : _interests.remove(i);
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

                if (!auth.isEmailVerified) ...[
                  const Text('이메일 계정 업그레이드'),
                  TextField(
                    controller: _upgradeEmailCtrl,
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                  TextField(
                    controller: _upgradePasswordCtrl,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    obscureText: true,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await auth.upgradeToEmailAccount(
                        _upgradeEmailCtrl.text.trim(),
                        _upgradePasswordCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('업그레이드 완료. 이메일을 확인하세요')),
                      );
                    },
                    child: const Text('이메일로 업그레이드'),
                  ),
                ],

                const SizedBox(height: 16),
                TextButton(
                  onPressed: auth.signOut,
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
