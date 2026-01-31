import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'package:go_router/go_router.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  bool _hasValidPhoto(AppState state) {
    final me = state.meOrNull;
    if (me == null) return false;
    return me.photoUrl != null && me.photoUrl!.trim().isNotEmpty;
  }

  bool _hasValidBio(AppState state) {
    final me = state.meOrNull;
    if (me == null) return false;
    final text = me.bio.trim();
    if (text.length < 20) return false;
    if (text == '안녕하세요' || text == '안녕하세요!') return false;
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
    final photoDone = _hasValidPhoto(state);
    final bioDone = _hasValidBio(state);
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
              const Text(
                '프로필 완성도',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('프로필 완성도 $percent%'),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 24),
              _ChecklistCard(
                title: '프로필 사진 추가',
                done: photoDone,
                onTap: () => context.go('/home/profile'),
              ),
              _ChecklistCard(
                title: '자기소개 작성',
                done: bioDone,
                onTap: () => context.go('/home/profile'),
              ),
              _ChecklistCard(
                title: '기본 정보 입력',
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
                  child: const Text('매칭 시작하기'),
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
