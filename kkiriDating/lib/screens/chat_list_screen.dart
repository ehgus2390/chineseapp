import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/app_state.dart';
import '../state/eligible_profiles_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/distance_filter_widget.dart';
import '../models/match_session.dart';
import '../models/profile.dart';
import '../state/notification_state.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _lastEligibleCount = 0;
  bool _showHeart = false;
  double _heartScale = 0.8;
  bool _animating = false;

  bool _navigating = false;
  bool _waitingLong = false;
  Timer? _waitingTimer;
  Timer? _countdownTimer;
  bool _queueActive = false;
  int _countdown = 10;
  bool _badgeCleared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_badgeCleared) return;
    _badgeCleared = true;
    context.read<NotificationState>().clearChatBadge();
  }

  @override
  void dispose() {
    _waitingTimer?.cancel();
    _countdownTimer?.cancel();
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

  void _enterMatchingQueue() {
    if (_queueActive) return;
    setState(() {
      _queueActive = true;
      _countdown = 10;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
        return;
      }
      setState(() => _countdown -= 1);
    });
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
            _Header(title: l.chatTitle),
            if (profileComplete) const DistanceFilterWidget(),
            Expanded(
              child: StreamBuilder<List<Profile>>(
                // IndexedStack keeps this widget mounted; no side effects on rebuild.
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
                      countdown: null,
                      onConnect: _enterMatchingQueue,
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
                      countdown: _queueActive ? _countdown : null,
                      onConnect: _enterMatchingQueue,
                    );
                  }

                  _resetWaiting();

                  final Profile target = list.first;

                  return StreamBuilder<MatchSession?>(
                    stream: _matchSessionStream(me!, target),
                    builder: (context, snapshot) {
                      final session = snapshot.data;

                      // Null/non-accepted sessions stay in queue UX without navigation.
                      if (session == null) {
                        _navigating = false;
                        return _ChatSearchingState(
                          emoji: l.chatSearchingEmoji,
                          title: '나와 잘 맞는 이성을 찾고 있습니다',
                          subtitle: '잠시만 기다려 주세요',
                          countdown: _queueActive ? _countdown : null,
                          onConnect: _enterMatchingQueue,
                        );
                      }
                      if (session.status == MatchStatus.pending) {
                        _navigating = false;
                        return const _ChatPendingState(
                          title: '상대 수락 대기 중',
                        );
                      }
                      if (session.status != MatchStatus.accepted) {
                        _navigating = false;
                        return _ChatWaitingState(
                          title: l.chatWaitingTitle,
                          subtitle: l.chatWaitingSubtitle,
                        );
                      }

                      if (session.chatRoomId == null ||
                          session.chatRoomId!.trim().isEmpty) {
                        return _ChatWaitingState(
                          title: l.chatWaitingTitle,
                          subtitle: l.chatWaitingSubtitle,
                        );
                      }

                      if (!_navigating) {
                        _navigating = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          // Guarded navigation avoids rebuild loops.
                          context.go('/home/chat/room/${session.chatRoomId}');
                        });
                      }

                      return _ChatWaitingState(
                        title: l.chatWaitingTitle,
                        subtitle: l.chatWaitingSubtitle,
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

Stream<MatchSession?> _matchSessionStream(Profile me, Profile target) {
  final List<String> ids = <String>[me.id, target.id]..sort();
  final String sessionId = ids.join('_');
  return FirebaseFirestore.instance
      .collection('match_sessions')
      .doc(sessionId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return MatchSession.fromDoc(doc);
  });
}

/* ───────────────────────── UI Components ───────────────────────── */

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(
            title,
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
    );
  }
}

class _ChatSearchingState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final int? countdown;
  final VoidCallback onConnect;

  const _ChatSearchingState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.countdown,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredText(
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
        const SizedBox(height: 14),
        if (countdown != null) ...[
          Text(
            '남은 시간 ${countdown}s',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: onConnect,
          child: const Text('연결하기'),
        ),
      ],
    );
  }
}

class _ChatWaitingState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ChatWaitingState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return _CenteredText(
      children: [
        Text(title, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _ChatPendingState extends StatelessWidget {
  final String title;

  const _ChatPendingState({required this.title});

  @override
  Widget build(BuildContext context) {
    return _CenteredText(
      children: [
        Text(title, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
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
    return _CenteredText(
      children: [
        AnimatedOpacity(
          opacity: showHeart ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedScale(
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
        FilledButton(onPressed: onConnect, child: Text(connectLabel)),
        const SizedBox(height: 8),
        TextButton(onPressed: onSkip, child: Text(skipLabel)),
      ],
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
    return _CenteredText(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontSize: 16),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onComplete, child: Text(actionLabel)),
      ],
    );
  }
}

class _CenteredText extends StatelessWidget {
  final List<Widget> children;
  const _CenteredText({required this.children});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}
