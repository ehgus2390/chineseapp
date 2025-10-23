import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  final idCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final d = snap.data!.data()!;
        nameCtrl.text = d['displayName'] ?? '';
        idCtrl.text = d['searchId'] ?? '';
        final photoUrl = d['photoUrl'];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person, size: 48) : null,
                  ),
                  Positioned(
                    right: -6, bottom: -6,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                        if (x == null) return;
                        final ref = FirebaseStorage.instance.ref('profiles/$uid.jpg');
                        await ref.putFile(File(x.path));
                        final url = await ref.getDownloadURL();
                        await auth.updateProfile(photoUrl: url);
                      },
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '닉네임')),
            const SizedBox(height: 8),
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: '검색 아이디 (searchId)')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await auth.updateProfile(displayName: nameCtrl.text.trim(), searchId: idCtrl.text.trim());
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
              },
              child: const Text('저장'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => auth.signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }
}
