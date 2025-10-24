import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/profile.dart';

Future<void> showProfileSheet(
  BuildContext context,
  Profile profile, {
  VoidCallback? onChat,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 32, backgroundImage: NetworkImage(profile.avatarUrl)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(profile.statusMessage, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l.languagesLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: profile.languages
                  .map(
                    (code) => Chip(
                      label: Text(code.toUpperCase()),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(l.aboutMe, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(profile.bio, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            if (onChat != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onChat,
                  child: Text(l.startChat),
                ),
              ),
          ],
        ),
      );
    },
  );
}
