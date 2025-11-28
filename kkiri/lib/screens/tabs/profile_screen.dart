import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/interest_options.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
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
  final _customInterestCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  String? _selectedGender;
  bool _isSaving = false;
  bool _interestsInitialized = false;
  final Set<String> _selectedInterests = {};
  final Set<String> _customInterests = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _customInterestCtrl.dispose();
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

    if (_nameCtrl.text != name) _nameCtrl.text = name;
    if (_bioCtrl.text != bio) _bioCtrl.text = bio;
    if (_ageCtrl.text != age) _ageCtrl.text = age;

    final gender = data['gender'] as String?;
    if (_selectedGender == null && gender != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedGender = gender);
      });
    }

    if (!_interestsInitialized) {
      final interests = ((data['interests'] as List?)?.cast<String>() ?? <String>[]);
      _selectedInterests
        ..clear()
        ..addAll(interests.where(kInterestOptionIds.contains));
      _customInterests
        ..clear()
        ..addAll(interests.where((interest) => !kInterestOptionIds.contains(interest)));
      _interestsInitialized = true;
    }
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final displayName = _nameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final ageText = _ageCtrl.text.trim();
    final interests = [..._selectedInterests, ..._customInterests].toList();
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
        SnackBar(content: Text(context.l10n.myProfileUpdated)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdateError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addCustomInterest() {
    final value = _customInterestCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _customInterests.add(value);
      _customInterestCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
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
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.bioLabel,
                    hintText: l10n.bioHint,
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
                        decoration: InputDecoration(
                          labelText: l10n.ageLabel,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: l10n.genderLabel,
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedGender,
                        items: const ['female', 'male', 'nonbinary', 'prefer_not']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(context.l10n.genderName(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedGender = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _interestSection(l10n),
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
                    label: Text(_isSaving ? l10n.saving : l10n.saveProfile),
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
                    label: Text(l10n.logout),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _interestSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.interestLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.interestsHelp),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: -8,
          children: kInterestOptions.map((option) {
            final selected = _selectedInterests.contains(option.id);
            return FilterChip(
              label: Text(l10n.interestLabelText(option.id)),
              avatar: Icon(option.icon, size: 18),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedInterests.add(option.id);
                  } else {
                    _selectedInterests.remove(option.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(l10n.customInterestLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customInterestCtrl,
                decoration: InputDecoration(
                  hintText: l10n.customInterestHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCustomInterest(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addCustomInterest, child: Text(l10n.addCustomInterest)),
          ],
        ),
        if (_customInterests.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: _customInterests
                .map(
                  (interest) => InputChip(
                    label: Text(interest),
                    onDeleted: () => setState(() => _customInterests.remove(interest)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
