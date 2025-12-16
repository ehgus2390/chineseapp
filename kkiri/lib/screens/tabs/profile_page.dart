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

  // ───────────────────────── 이미지 선택 ─────────────────────────
  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return null;
    final storage = StorageService();
    return storage.uploadProfileImage(uid: uid, file: _pickedImage!);
  }

  // ───────────────────────── 프로필 저장 ─────────────────────────
  Future<void> _saveProfile(
      AuthProvider auth,
      String uid,
      Map<String, dynamic>? data,
      ) async {
    setState(() => _saving = true);
    try {
      final url = await _uploadPhoto(uid) ?? data?['photoUrl'] as String?;
      await auth.updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        photoUrl: url,
        age: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
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

  // ───────────────────────── ⚙️ 설정 메뉴 ─────────────────────────
  void _openProfileActions(BuildContext context, String targetUid) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('신고하기'),
                onTap: () {
                  Navigator.pop(context);
                  _openReportDialog(context, targetUid);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('차단하기'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmBlock(context, targetUid);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── 신고 다이얼로그 ─────────────────────────
  void _openReportDialog(BuildContext context, String targetUid) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('신고하기'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '신고 사유를 입력해주세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _submitReport(context, targetUid, controller.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('신고'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport(
      BuildContext context,
      String targetUid,
      String reason,
      ) async {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser!.uid;

    await FirebaseFirestore.instance.collection('reports').add({
      'reporterUid': myUid,
      'targetUid': targetUid,
      'type': 'profile',
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ───────────────────────── 차단 ─────────────────────────
  void _confirmBlock(BuildContext context, String targetUid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('차단'),
          content: const Text('이 사용자를 차단하면 서로 보이지 않게 됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _blockUser(context, targetUid);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('차단'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser(BuildContext context, String targetUid) async {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .doc(targetUid)
        .set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ───────────────────────── UI ─────────────────────────
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

        if (!_initialised && data != null) {
          _initialised = true;
          _displayNameController.text =
              data['displayName'] as String? ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _gender = data['gender'] as String?;
          _bioController.text = data['bio'] as String? ?? '';
          _interests = List<String>.from(data['interests'] ?? []);
        }

        final photoUrl = _pickedImage != null
            ? null
            : data?['photoUrl'] as String?;

        return Scaffold(
          appBar: AppBar(
            title: const Text('내 프로필'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _openProfileActions(context, uid),
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
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('사진 변경'),
                ),

                const SizedBox(height: 16),

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
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '내 소개'),
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
                            _interests.add(interest);
                          } else {
                            _interests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
