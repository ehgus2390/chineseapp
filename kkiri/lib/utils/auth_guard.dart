import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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

  final t = AppLocalizations.of(context);
  final shouldLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t?.requireEmailLoginTitle ?? 'Login required'),
      content: Text(
        t?.requireEmailLoginMessage(featureName) ??
            'Login required to use $featureName.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(t?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t?.login ?? 'Login'),
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

  return false;
}
