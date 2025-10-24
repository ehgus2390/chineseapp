import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/notification_labels.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AppLocalizations l = AppLocalizations.of(context);
    final me = state.me;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(me.avatarUrl),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            me.statusMessage,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final controller = TextEditingController(text: me.statusMessage);
                            final String? result = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(l.editStatus),
                                  content: TextField(
                                    controller: controller,
                                    maxLines: 2,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(l.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(context).pop(controller.text),
                                      child: Text(l.ok),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (result != null && result.trim().isNotEmpty) {
                              state.updateStatus(result.trim());
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: me.languages
                          .map(
                            (code) => Chip(
                              label: Text(code.toUpperCase()),
                              backgroundColor: Colors.white.withOpacity(0.8),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(l.aboutMe, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(me.bio, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 24),
        Text(l.notificationSettings, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: state.notificationOptions.entries.map((entry) {
              return SwitchListTile(
                value: entry.value,
                title: Text(notificationLabel(l, entry.key)),
                onChanged: (bool value) => state.updateNotification(entry.key, value),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(l.communityTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...state.highlightedCommunityInsights.map((key) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _insightText(l, key),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }),
      ],
    );
  }

  String _insightText(AppLocalizations l, String key) {
    switch (key) {
      case 'insightProfileUpdate':
        return l.insightProfileUpdate;
      case 'insightShareTips':
        return l.insightShareTips;
      case 'insightNewPost':
        return l.insightNewPost;
      default:
        return key;
    }
  }
}
