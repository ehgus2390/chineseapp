// lib/screens/tabs/community_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'university_community_feed_screen.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  void _showEmailOnlySnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email login required to write posts.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AppState>();
    final user = authState.user;
    final isEmailUser = user != null && !user.isAnonymous;

    return Stack(
      children: [
        const UniversityCommunityFeedScreen(),
        Positioned(
          right: 20,
          bottom: 80,
          child: FloatingActionButton(
            onPressed: () {
              if (!isEmailUser) {
                _showEmailOnlySnackBar(context);
                return;
              }
            },
            child: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }
}
