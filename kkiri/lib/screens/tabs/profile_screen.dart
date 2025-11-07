import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  String? _selectedGender;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (result != null) {
      setState(() => _image = File(result.path));
    }
  }

  Future<void> _uploadPhoto() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null || _image == null) return;
    final storage = StorageService();
    final url = await storage.uploadProfileImage(uid: uid, file: _image!);
    await context.read<AuthProvider>().updateProfilePhoto(url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필 사진이 변경되었습니다.')),
    );
    setState(() => _image = null);
  }

  void _syncControllers(Map<String, dynamic> data) {
    final name = data['displayName'] as String? ?? '';
    final bio = data['bio'] as String? ?? '';
    final age = data['age']?.toString() ?? '';
    final interests = ((data['interests'] as List?)?.cast<String>() ?? <String>[]).join(', ');

    if (_nameCtrl.text != name) _nameCtrl.text = name;
    if (_bioCtrl.text != bio) _bioCtrl.text = bio;
    if (_ageCtrl.text != age) _ageCtrl.text = age;
    if (_interestsCtrl.text != interests) _interestsCtrl.text = interests;

    final gender = data['gender'] as String?;
    if (_selectedGender == null && gender != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedGender = gender);
      });
    }
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final displayName = _nameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final ageText = _ageCtrl.text.trim();
    final interests = _interestsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);

    setState(() => _isSaving = true);
    try {
      await auth.updateProfile(
        displayName: displayName.isEmpty ? null : displayName,
        bio: bio.isEmpty ? null : bio,
        age: age,
        gender: _selectedGender,
        interests: interests,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 업데이트되었습니다.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 데이팅 프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          _syncControllers(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                                ? NetworkImage(user.photoURL!)
                                : const AssetImage('assets/images/logo.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.pinkAccent),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ElevatedButton.icon(
                      onPressed: _uploadPhoto,
                      icon: const Icon(Icons.upload),
                      label: const Text('새 프로필 사진 저장'),
                    ),
                  ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '한 줄 소개',
                    hintText: '자신을 어필해보세요!',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '나이',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '성별',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'female', child: Text('여성')),
                          DropdownMenuItem(value: 'male', child: Text('남성')),
                          DropdownMenuItem(value: 'nonbinary', child: Text('논바이너리')),
                          DropdownMenuItem(value: 'prefer_not', child: Text('선택 안 함')),
                        ],
                        onChanged: (value) => setState(() => _selectedGender = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _interestsCtrl,
                  decoration: const InputDecoration(
                    labelText: '관심사',
                    hintText: '여행, 영화, 요리',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('쉼표(,)로 구분해서 입력하세요.'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite),
                    label: Text(_isSaving ? '저장 중...' : '프로필 저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
