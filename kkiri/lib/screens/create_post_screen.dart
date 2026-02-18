import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/community_profile_repository.dart';
import '../services/community_post_repository.dart';
import '../state/app_state.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const List<String> _allowedCategories = [
    'free',
    'question',
    'life',
    'housing',
    'parttime',
    'visa',
    'language',
    'market',
    'dating',
  ];

  final _textController = TextEditingController();
  final CommunityProfileRepository _profileRepository =
      CommunityProfileRepository();
  final CommunityPostRepository _postRepository = CommunityPostRepository();

  String _type = 'free';
  bool _isAnonymous = true;
  bool _submitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = context.read<AppState>().user?.uid;
    final text = _textController.text.trim();

    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required.')),
      );
      return;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text is required.')),
      );
      return;
    }
    if (!_allowedCategories.contains(_type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid category selected.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final profile = await _profileRepository.getProfileData(uid);
      final profileSchool = (profile?['school'] is String)
          ? (profile?['school'] as String).trim()
          : '';
      final profileRegion = (profile?['region'] is String)
          ? (profile?['region'] as String).trim()
          : '';

      final school = profileSchool;
      final region = profileRegion;

      await _postRepository.createPost(
        uid: uid,
        text: text,
        type: _type,
        school: school,
        region: region,
        isAnonymous: _isAnonymous,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (message.contains('Posting restricted due to policy violation.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account is temporarily restricted from posting.',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create post.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: _allowedCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _type = value);
              },
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Post anonymously'),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
