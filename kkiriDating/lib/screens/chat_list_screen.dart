import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/eligible_profiles_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/distance_filter_widget.dart';
import '../models/match.dart';
import '../models/profile.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final Set<String> _skippedIds = <String>{};
  int _lastEligibleCount = 0;
  bool _showHeart = false;
  double _heartScale = 0.8;
  bool _animating = false;
  bool _navigating = false;
  bool _waitingLong = false;
  Timer? _waitingTimer;

  @override
  void dispose() {
    _waitingTimer?.cancel();
    super.dispose();
  }

  void _scheduleLongWait() {
    if (_waitingTimer != null) return;
    _waitingTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() => _waitingLong = true);
      _waitingTimer = null;
    });
  }

  void _resetWaiting() {
    _waitingTimer?.cancel();
    _waitingTimer = null;
    if (_waitingLong) {
      _waitingLong = false;
    }
  }

  void _syncAnimation(int count) {
    if (count == 0) {
      _lastEligibleCount = 0;
      if (_showHeart || _heartScale != 0.8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
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
      _heartScale = 0.8;
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (!mounted) return;
    setState(() => _heartScale = 1.2);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _heartScale = 1.0);
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
                  final visible =
                      list.where((p) => !_skippedIds.contains(p.id)).toList();
                  if (visible.isEmpty) {
                    _navigating = false;
                    _scheduleLongWait();
                    if (_waitingLong) {
                      return _ChatWaitingState(
                        title: l.chatWaitingTitle,
                        subtitle: l.chatWaitingSubtitle,
                      );
                    }
                    return _ChatSearchingState(
                      emoji: l.chatSearchingEmoji,
                      title: l.chatSearchingTitle,
                      subtitle: l.chatSearchingSubtitle,
                    );
                  }
                  _resetWaiting();
                  final Profile target = visible.first;
                  final List<String> ids = <String>[me!.id, target.id]..sort();
                  final String matchId = ids.join('_');
                  return StreamBuilder<MatchSession?>(
                    stream: state.watchMatchSession(target.id),
                    builder: (context, sessionSnapshot) {
                      final session = sessionSnapshot.data;
                      final bool meReady =
                          session?.ready[me.id] == true;
                      final bool otherReady = session?.pendingUserIds
                              .where((id) => id != me.id)
                              .every((id) => session?.ready[id] == true) ==
                          true;
                      if (session != null && session.connected) {
                        if (_navigating) {
                          return _ChatWaitingState(
                            title: l.chatWaitingTitle,
                            subtitle: l.chatWaitingSubtitle,
                          );
                        }
                        _navigating = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          context.go('/home/chat/room/$matchId');
                        });
                        return _ChatWaitingState(
                          title: l.chatWaitingTitle,
                          subtitle: l.chatWaitingSubtitle,
                        );
                      }
                      if (meReady && otherReady) {
                        if (_navigating) {
                          return _ChatWaitingState(
                            title: l.chatWaitingTitle,
                            subtitle: l.chatWaitingSubtitle,
                          );
                        }
                        _navigating = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          await state.ensureConnectedMatch(target.id);
                          if (!context.mounted) return;
                          context.go('/home/chat/room/$matchId');
                        });
                        return _ChatWaitingState(
                          title: l.chatWaitingTitle,
                          subtitle: l.chatWaitingSubtitle,
                        );
                      }
                      if (meReady && !otherReady) {
                        _navigating = false;
                        return _WaitingForOther(
                          title: l.waitingForOtherUser,
                          emoji: l.chatSearchingEmoji,
                        );
                      }
                      _navigating = false;
                      return _ChatConsentState(
                        title: l.matchingConsentTitle,
                        subtitle: l.matchingConsentSubtitle,
                        connectLabel: l.matchingConnectButton,
                        skipLabel: l.matchingSkipButton,
                        emoji: l.chatSearchingEmoji,
                        showHeart: _showHeart,
                        heartScale: _heartScale,
                        onConnect: () async {
                          await state.setMatchConsent(target.id, true);
                        },
                        onSkip: () async {
                          _skippedIds.add(target.id);
                          await state.skipMatchSession(target.id);
                          if (!mounted) return;
                          setState(() {});
                        },
                      );
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

class _WaitingForOther extends StatelessWidget {
  final String title;
  final String emoji;

  const _WaitingForOther({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatConsentState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String connectLabel;
  final String skipLabel;
  final String emoji;
  final bool showHeart;
  final double heartScale;
  final VoidCallback onConnect;
  final VoidCallback onSkip;

  const _ChatConsentState({
    required this.title,
    required this.subtitle,
    required this.connectLabel,
    required this.skipLabel,
    required this.emoji,
    required this.showHeart,
    required this.heartScale,
    required this.onConnect,
    required this.onSkip,
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
            FilledButton(
              onPressed: onConnect,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(connectLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSkip,
              child: Text(skipLabel),
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
