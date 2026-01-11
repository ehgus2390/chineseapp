import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/eligible_profiles_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/distance_filter_widget.dart';
import '../models/profile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);
    final eligible = context.watch<EligibleProfilesProvider>();
    final me = state.meOrNull;
    final bool profileComplete = me != null && state.isProfileReady(me);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F4),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Text(
                    l.chatTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            if (profileComplete) const DistanceFilterWidget(),
            Expanded(
              child: StreamBuilder<List<Profile>>(
                stream: eligible.stream,
                initialData: const <Profile>[],
                builder: (context, snapshot) {
                  if (!profileComplete) {
                    return _ProfileCompletionPrompt(
                      onComplete: () => context.go('/home/profile'),
                    );
                  }
                  if (snapshot.hasError) {
                    debugPrint('watchNearbyUsers error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Something went wrong. Please try again.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  final list = snapshot.data ?? const <Profile>[];
                  if (list.isEmpty) {
                    return const _ChatEmptyState();
                  }
                  final Profile target = list.first;
                  return _ChatCtaCard(
                    profile: target,
                    onStart: () async {
                      final matchId = await state.ensureChatRoom(target.id);
                      if (!context.mounted) return;
                      context.go('/home/chat/room/$matchId');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('💗', style: TextStyle(fontSize: 32)),
            SizedBox(height: 12),
            Text(
              '조건에 맞는 친구를 찾고 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatCtaCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onStart;

  const _ChatCtaCard({required this.profile, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = profile.photoUrl;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: photoUrl == null || photoUrl.isEmpty
                    ? const Center(child: Icon(Icons.person, size: 64))
                    : Image.network(photoUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${profile.name} · ${profile.age}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('💬 지금 채팅 시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionPrompt extends StatelessWidget {
  final VoidCallback onComplete;

  const _ProfileCompletionPrompt({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '프로필을 완성해야 추천을 받을 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onComplete,
              child: const Text('프로필 완성하기'),
            ),
          ],
        ),
      ),
    );
  }
}
