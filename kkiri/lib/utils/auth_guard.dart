import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

Future<bool> requireEmailLogin(
  BuildContext context,
  String featureName,
) async {
  final auth = context.read<AuthProvider>();
  final user = auth.currentUser;

  if (user != null && !user.isAnonymous) {
    return true;
  }

  final shouldLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: const Text('This feature requires login'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Login with Email'),
        ),
      ],
    ),
  );

  if (shouldLogin == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  final updatedUser = auth.currentUser;
  return updatedUser != null && !updatedUser.isAnonymous;
}
