import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/eligible_profiles_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/distance_filter_widget.dart';
import '../models/profile.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _lastEligibleCount = 0;
  bool _showCta = false;
  bool _showHeart = false;
  double _heartScale = 0.8;
  bool _animating = false;

  void _syncAnimation(int count) {
    if (count == 0) {
      _lastEligibleCount = 0;
      if (_showCta || _showHeart || _heartScale != 0.8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _showCta = false;
            _showHeart = false;
            _heartScale = 0.8;
          });
        });
      }
      return;
    }

    if (_lastEligibleCount == 0) {
      _lastEligibleCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runMatchAnimation());
      return;
    }
    _lastEligibleCount = count;
  }

  Future<void> _runMatchAnimation() async {
    if (_animating) return;
    _animating = true;
    if (!mounted) return;
    setState(() {
      _showHeart = true;
      _showCta = false;
      _heartScale = 0.8;
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (!mounted) return;
    setState(() => _heartScale = 1.2);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _heartScale = 1.0);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _showCta = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _animating = false;
  }

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
                      title: l.profileCompleteTitle,
                      actionLabel: l.profileCompleteAction,
                      onComplete: () => context.go('/home/profile'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _ChatSearchingState(
                      emoji: l.chatSearchingEmoji,
                      title: l.chatSearchingTitle,
                      subtitle: l.chatSearchingSubtitle,
                    );
                  }
                  if (snapshot.hasError) {
                    return _ChatWaitingState(
                      title: l.chatWaitingTitle,
                      subtitle: l.chatWaitingSubtitle,
                    );
                  }
                  final list = snapshot.data ?? const <Profile>[];
                  _syncAnimation(list.length);
                  if (list.isEmpty) {
                    return _ChatWaitingState(
                      title: l.chatWaitingTitle,
                      subtitle: l.chatWaitingSubtitle,
                    );
                  }
                  final Profile target = list.first;
                  return _ChatMatchState(
                    title: l.chatMatchTitle,
                    subtitle: l.chatMatchSubtitle,
                    buttonLabel: l.chatStartButton,
                    emoji: l.chatSearchingEmoji,
                    showHeart: _showHeart,
                    heartScale: _heartScale,
                    showCta: _showCta,
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

class _ChatSearchingState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _ChatSearchingState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatWaitingState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ChatWaitingState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMatchState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String emoji;
  final bool showHeart;
  final double heartScale;
  final bool showCta;
  final VoidCallback onStart;

  const _ChatMatchState({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.emoji,
    required this.showHeart,
    required this.heartScale,
    required this.showCta,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: showHeart ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedScale(
                key: const ValueKey('match-heart'),
                scale: heartScale,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Text(emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: showCta ? 1 : 0,
              duration: const Duration(milliseconds: 240),
              child: FilledButton(
                onPressed: showCta ? onStart : null,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionPrompt extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onComplete;

  const _ProfileCompletionPrompt({
    required this.title,
    required this.actionLabel,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onComplete,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
