import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = context.l10n;
    final currentCode = settings.locale?.languageCode ?? Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.languageSectionTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.languageSectionSubtitle),
          const SizedBox(height: 12),
          ...AppLocalizations.supportedLocales.map((locale) {
            final code = locale.languageCode;
            return Card(
              child: RadioListTile<String>(
                value: code,
                groupValue: currentCode,
                title: Text(l10n.languageName(code)),
                onChanged: (value) async {
                  if (value == null || value == currentCode) return;
                  final messenger = ScaffoldMessenger.of(context);
                  await settings.updateLocale(Locale(value));
                  await context.read<AuthProvider>().updateProfile(lang: value);
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.languageUpdated)),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
