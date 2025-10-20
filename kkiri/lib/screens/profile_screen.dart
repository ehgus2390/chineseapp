import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/language_badge.dart';
import '../l10n/app_localizations.dart';
import '../state/locale_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> available = <String>['ko', 'en', 'ja', 'zh'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final me = state.me;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(me.avatarUrl),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(me.name, style: Theme.of(context).textTheme.titleLarge),
              Text('${l.nationality}: ${me.nationality}')
            ]),
          ],
        ),
        const SizedBox(height: 16),
        Text(l.yourLanguages, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: me.languages.map((c) => LanguageBadge(code: c)).toList(),
        ),
        const SizedBox(height: 24),
        Text(l.preferences, style: Theme.of(context).textTheme.titleMedium),
        Text(l.prefTarget),
        Wrap(
          spacing: 8,
          children: available.map((String code) {
            final bool selected = state.myPreferredLanguages.contains(code);
            return FilterChip(
              label: Text(code.toUpperCase()),
              selected: selected,
              onSelected: (bool value) async {
                await state.setPreferredLanguage(code, value);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            await state.savePreferredLanguages();
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
