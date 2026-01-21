import 'dart:async';
import 'dart:ui';
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
  bool _timeoutReached = false;
  bool _ignorePendingSession = false;
  static const int _queueDurationSeconds = 10;

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

  Future<void> _enterMatchingQueue() async {
    if (_queueActive) return;
    try {
      await context.read<AppState>().enterAutoMatchQueue();
    } catch (_) {
      // Keep UI responsive even if queue entry fails.
    }
    if (!mounted) return;
    setState(() {
      _queueActive = true;
      _countdown = _queueDurationSeconds;
      _timeoutReached = false;
      _ignorePendingSession = false;
    });
  }

  void _startCountdownIfNeeded() {
    if (_countdownTimer != null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _queueActive = false;
          _timeoutReached = true;
          _ignorePendingSession = true;
        });
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _timeoutReached = false);
        });
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _queueActive = false;
  }

  Future<void> _setSessionStatus(MatchSession session, String status) async {
    await FirebaseFirestore.instance
        .collection('match_sessions')
        .doc(session.id)
        .set(<String, dynamic>{
      'status': status,
      'respondedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
                    _stopCountdown();
                    return _ChatSearchingState(
                      emoji: l.chatSearchingEmoji,
                      title: l.queueSearchingTitle,
                      subtitle: l.queueSearchingSubtitle,
                      countdownText: null,
                      showConnect: !_queueActive,
                      connectLabel: l.queueConnect,
                      onConnect: () => _enterMatchingQueue(),
                    );
                  }

                  if (snapshot.hasError) {
                    _stopCountdown();
                    return _ChatWaitingState(
                      title: l.chatWaitingTitle,
                      subtitle: l.chatWaitingSubtitle,
                    );
                  }

                  final list = snapshot.data ?? const <Profile>[];
                  _syncAnimation(list.length);

                  if (list.isEmpty) {
                    _navigating = false;
                    if (_queueActive) {
                      _stopCountdown();
                      return _ChatSearchingState(
                        emoji: l.chatSearchingEmoji,
                        title: l.queueSearchingTitle,
                        subtitle: l.queueSearchingSubtitle,
                        countdownText: null,
                        showConnect: false,
                        connectLabel: l.queueConnect,
                        onConnect: _enterMatchingQueue,
                      );
                    }
                    _scheduleLongWait();
                    if (_waitingLong) {
                      _stopCountdown();
                      return _ChatWaitingState(
                        title: l.chatWaitingTitle,
                        subtitle: l.chatWaitingSubtitle,
                      );
                    }
                    _stopCountdown();
                    return _ChatSearchingState(
                      emoji: l.chatSearchingEmoji,
                      title: l.queueSearchingTitle,
                      subtitle: l.queueSearchingSubtitle,
                      countdownText: null,
                      showConnect: !_queueActive,
                      connectLabel: l.queueConnect,
                      onConnect: _enterMatchingQueue,
                    );
                  }

                  _resetWaiting();

                  final Profile target = list.first;

                  return StreamBuilder<MatchSession?>(
                    stream: _matchSessionStream(me!, target),
                    builder: (context, snapshot) {
                      final session = snapshot.data;

                      if (_timeoutReached) {
                        _navigating = false;
                        _stopCountdown();
                        return _ChatTimeoutState(
                          title: l.queueTimeout,
                        );
                      }

                      // Null/non-accepted sessions stay in queue UX without navigation.
                      if (session == null) {
                        _navigating = false;
                        _stopCountdown();
                        return _ChatSearchingState(
                          emoji: l.chatSearchingEmoji,
                          title: l.queueSearchingTitle,
                          subtitle: l.queueSearchingSubtitle,
                          countdownText: null,
                          showConnect: !_queueActive,
                          connectLabel: l.queueConnect,
                          onConnect: _enterMatchingQueue,
                        );
                      }
                      if (session.status == MatchStatus.searching) {
                        _navigating = false;
                        _stopCountdown();
                        return _ChatSearchingState(
                          emoji: l.chatSearchingEmoji,
                          title: l.queueSearchingTitle,
                          subtitle: l.queueSearchingSubtitle,
                          countdownText: null,
                          showConnect: false,
                          connectLabel: l.queueConnect,
                          onConnect: _enterMatchingQueue,
                        );
                      }
                      if (session.status == MatchStatus.pending) {
                        _navigating = false;
                        if (_ignorePendingSession) {
                          _stopCountdown();
                          return _ChatSearchingState(
                            emoji: l.chatSearchingEmoji,
                            title: l.queueSearchingTitle,
                            subtitle: l.queueSearchingSubtitle,
                            countdownText: null,
                            showConnect: true,
                            connectLabel: l.queueConnect,
                            onConnect: _enterMatchingQueue,
                          );
                        }
                        _startCountdownIfNeeded();
                        return Stack(
                          children: [
                            _ChatSearchingState(
                              emoji: l.chatSearchingEmoji,
                              title: l.queueSearchingTitle,
                              subtitle: l.queueSearchingSubtitle,
                              countdownText: null,
                              showConnect: false,
                              connectLabel: l.queueConnect,
                              onConnect: _enterMatchingQueue,
                            ),
                            _MatchPendingOverlay(
                              profile: target,
                              countdownSeconds: _countdown,
                              totalSeconds: _queueDurationSeconds,
                              remainingLabel: l.queueRemainingTime(
                                _countdown.toString(),
                              ),
                              acceptLabel: l.queueAccept,
                              declineLabel: l.queueDecline,
                              onAccept: () async {
                                _stopCountdown();
                                if (mounted) {
                                  setState(() => _ignorePendingSession = false);
                                }
                                await _setSessionStatus(session, 'pending');
                              },
                              onDecline: () async {
                                _stopCountdown();
                                if (mounted) {
                                  setState(() => _ignorePendingSession = true);
                                }
                                await _setSessionStatus(session, 'expired');
                              },
                            ),
                          ],
                        );
                      }
                      if (session.status != MatchStatus.accepted) {
                        _navigating = false;
                        _stopCountdown();
                        return _ChatWaitingState(
                          title: l.chatWaitingTitle,
                          subtitle: l.chatWaitingSubtitle,
                        );
                      }

                      if (session.chatRoomId == null ||
                          session.chatRoomId!.trim().isEmpty) {
                        _stopCountdown();
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
  final String? subtitle;
  final String? countdownText;
  final bool showConnect;
  final String connectLabel;
  final VoidCallback onConnect;

  const _ChatSearchingState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.countdownText,
    required this.showConnect,
    required this.connectLabel,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredText(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 16)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
        const SizedBox(height: 14),
        if (countdownText != null) ...[
          Text(
            countdownText!,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
        ],
        if (showConnect)
          FilledButton(
            onPressed: onConnect,
            child: Text(connectLabel),
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

class _ChatTimeoutState extends StatelessWidget {
  final String title;

  const _ChatTimeoutState({required this.title});

  @override
  Widget build(BuildContext context) {
    return _CenteredText(
      children: [
        Text(title, style: const TextStyle(fontSize: 18)),
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

class _MatchPendingOverlay extends StatelessWidget {
  final Profile profile;
  final int countdownSeconds;
  final int totalSeconds;
  final String remainingLabel;
  final String acceptLabel;
  final String declineLabel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _MatchPendingOverlay({
    required this.profile,
    required this.countdownSeconds,
    required this.totalSeconds,
    required this.remainingLabel,
    required this.acceptLabel,
    required this.declineLabel,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final double progress =
        (countdownSeconds / totalSeconds).clamp(0.0, 1.0);
    final String ageText = profile.age > 0 ? profile.age.toString() : '';
    final String nameText = profile.name.trim();
    final String title = ageText.isEmpty ? nameText : '$nameText, $ageText';

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withOpacity(0.35)),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: profile.photoUrl != null &&
                            profile.photoUrl!.trim().isNotEmpty
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null ||
                            profile.photoUrl!.trim().isEmpty
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                const SizedBox(height: 4),
                Text(remainingLabel),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        child: Text(declineLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CircularAcceptButton(
                        progress: progress,
                        label: acceptLabel,
                        onPressed: onAccept,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircularAcceptButton extends StatelessWidget {
  final double progress;
  final String label;
  final VoidCallback onPressed;

  const _CircularAcceptButton({
    required this.progress,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: const Color(0xFFE7D8DD),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C5B6A)),
          ),
        ),
        Material(
          color: Colors.transparent,
          elevation: 3,
          shape: const CircleBorder(),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}


