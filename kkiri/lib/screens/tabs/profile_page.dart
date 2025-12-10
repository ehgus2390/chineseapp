// lib/screens/tabs/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final email = user?.email ?? 'Unknown user';
    final verified = user?.emailVerified ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Email: $email'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                verified ? Icons.verified : Icons.verified_outlined,
                color: verified ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verified
                      ? 'Email verified. You can view other profiles.'
                      : 'Verify your email to unlock profile viewing.',
                ),
              ),
              if (!verified)
                TextButton(
                  onPressed: appState.sendVerificationEmail,
                  child: const Text('Send link'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: appState.refreshUser,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh verification status'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.read<AppState>().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}
