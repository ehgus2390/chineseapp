import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../l10n/app_localizations.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  bool _hasValidPhoto(AppState state) {
    final me = state.meOrNull;
    if (me == null) return false;
    return me.photoUrl != null && me.photoUrl!.trim().isNotEmpty;
  }

  bool _hasValidBio(AppState state, AppLocalizations l) {
    final me = state.meOrNull;
    if (me == null) return false;
    final text = me.bio.trim();
    if (text.length < 20) return false;
    if (text == l.profileBioPlaceholder || text == l.profileBioPlaceholderAlt) {
      return false;
    }
    return true;
  }

  bool _hasBasicInfo(AppState state) {
    final me = state.meOrNull;
    if (me == null) return false;
    final gender = me.gender.trim();
    final ageOk = me.age > 0;
    final hasPreference = state.myPreferredLanguages.isNotEmpty;
    return gender.isNotEmpty && ageOk && hasPreference;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);
    final photoDone = _hasValidPhoto(state);
    final bioDone = _hasValidBio(state, l);
    final basicDone = _hasBasicInfo(state);
    final doneCount = [photoDone, bioDone, basicDone].where((v) => v).length;
    final progress = doneCount / 3.0;
    final percent = (progress * 100).round();
    final completed = state.isProfileComplete;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                l.profileCompletionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(l.profileCompletionProgress(percent.toString())),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 24),
              _ChecklistCard(
                title: l.profileCompletionPhoto,
                done: photoDone,
                onTap: () => context.go('/home/profile'),
              ),
              _ChecklistCard(
                title: l.profileCompletionBio,
                done: bioDone,
                onTap: () => context.go('/home/profile'),
              ),
              _ChecklistCard(
                title: l.profileCompletionBasicInfo,
                done: basicDone,
                onTap: () => context.go('/home/profile'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: completed
                      ? () async {
                          await state.setProfileCompleted();
                        }
                      : null,
                  child: Text(l.profileCompletionCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onTap;

  const _ChecklistCard({
    required this.title,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? Colors.green : Colors.grey,
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
