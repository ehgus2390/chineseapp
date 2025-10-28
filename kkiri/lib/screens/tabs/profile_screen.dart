import 'dart:io';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (user?.photoURL != null)
                        ? NetworkImage(user!.photoURL!)
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
            Text(user?.displayName ?? '익명 사용자',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => auth.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
