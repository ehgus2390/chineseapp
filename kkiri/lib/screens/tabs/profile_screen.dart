import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final _picker = ImagePicker();
  String? _selectedGender;
  String? _selectedCountry;

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _upload() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;
    final storage = StorageService();
    if (_image == null) return;
    final url = await storage.uploadProfileImage(uid: uid, file: _image!);
    await context.read<AuthProvider>().updateProfilePhoto(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필 사진이 변경되었습니다.')),
    );
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    if (_selectedGender == null || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성별과 국적을 모두 선택해주세요.')),
      );
      return;
    }

    await auth.updateProfile(
      gender: _selectedGender,
      country: _selectedCountry,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};
          _selectedGender ??= data['gender'] as String?;
          _selectedCountry ??= data['country'] as String?;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: (user.photoURL != null)
                            ? NetworkImage(user.photoURL!)
                            : const AssetImage('assets/images/logo.png')
                        as ImageProvider,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(user.displayName ?? '익명 사용자',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                if (_image != null)
                  Column(
                    children: [
                      Image.file(_image!, width: 100, height: 100, fit: BoxFit.cover),
                      ElevatedButton.icon(
                        onPressed: _upload,
                        icon: const Icon(Icons.upload),
                        label: const Text('프로필 업로드'),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text(
                  '일본 여성(JP)과 한국 남성(KR)만 서로를 볼 수 있도록 성별과 국적을 선택해주세요.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: '성별'),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('여성')),
                    DropdownMenuItem(value: 'male', child: Text('남성')),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: const InputDecoration(labelText: '국적'),
                  items: const [
                    DropdownMenuItem(value: 'JP', child: Text('일본')),
                    DropdownMenuItem(value: 'KR', child: Text('대한민국')),
                  ],
                  onChanged: (value) => setState(() => _selectedCountry = value),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('저장'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => auth.signOut(),
                        icon: const Icon(Icons.logout),
                        label: const Text('로그아웃'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
