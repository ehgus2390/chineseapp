import 'package:flutter/material.dart';
import '../models/profile.dart';
import 'language_badge.dart';
import '../l10n/app_localizations.dart';

class ProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onLike,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: profile.avatarUrl.isEmpty
                ? Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 64),
                  )
                : Image.network(profile.avatarUrl, fit: BoxFit.cover),
          ),
          ListTile(
            title: Text(
              profile.country.isEmpty
                  ? '${profile.name} · ${profile.age}'
                  : '${profile.name} · ${profile.age} · ${profile.country}',
            ),
            subtitle: Text(profile.bio),
          ),
          Wrap(
            spacing: 8,
            children:
                profile.languages.map((c) => LanguageBadge(code: c)).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: onPass,
                child: Text(l.pass),
              ),
              FilledButton(
                onPressed: onLike,
                child: Text(l.like),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
