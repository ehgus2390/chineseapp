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
      final url = await _uploadPhoto(uid) ?? data?['photoUrl'];
      await auth.updateProfile(
        displayName: _displayNameController.text.trim(),
        photoUrl: url,
        age: int.tryParse(_ageController.text),
        gender: _gender,
        bio: _bioController.text,
        interests: _interests,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ⚙️ 신고 / 차단
  void _openProfileActions(String myUid) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('신고하기'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance.collection('reports').add({
                    'type': 'profile',
                    'reporterUid': myUid,
                    'targetUid': myUid,
                    'reason': '부적절한 프로필',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('차단하기'),
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (_, snapshot) {
        final data = snapshot.data?.data();

        if (!_initialised && data != null) {
          _initialised = true;
          _displayNameController.text = data['displayName'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _gender = data['gender'];
          _bioController.text = data['bio'] ?? '';
          _interests = List<String>.from(data['interests'] ?? []);
        }

        final photoUrl = _pickedImage != null ? null : data?['photoUrl'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('내 프로필'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _openProfileActions(uid),
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
                      : photoUrl != null
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/images/logo.png')
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
                  decoration: const InputDecoration(labelText: '내 소개'),
                  maxLines: 3,
                ),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () => _saveProfile(auth, uid, data),
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
