import 'package:flutter/material.dart';
import '../models/profile.dart';
import 'language_badge.dart';

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
    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(profile.avatarUrl, fit: BoxFit.cover),
          ),
          ListTile(
            title: Text('${profile.name} • ${profile.nationality}'),
            subtitle: Text(profile.bio),
          ),
          Wrap(
            spacing: 8,
            children: profile.languages.map((c) => LanguageBadge(code: c)).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: onPass,
                child: const Icon(Icons.close),
              ),
              FilledButton(
                onPressed: onLike,
                child: const Icon(Icons.favorite),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
