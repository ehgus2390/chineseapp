import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kkiri/l10n/app_localizations.dart';
import '../state/app_state.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.onboardingTitle)),
      body: Center(
        child: FilledButton(
          onPressed: () async {
            await context.read<AppState>().completeOnboarding();
            if (context.mounted) context.go('/home/discover');
          },
          child: Text(l.continueAction),
        ),
      ),
    );
  }
}
