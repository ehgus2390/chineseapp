import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/app_state.dart';
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
  bool _navigating = false;
  Timer? _countdownTimer;
  int _countdown = 10;
  bool _badgeCleared = false;
  bool _timeoutReached = false;
  bool _queueActive = false;
  String? _activePendingSessionId;
  String? _ignoredSessionId;
  bool _requeueScheduled = false;
  String? _handledEndSessionId;
  static const int _queueDurationSeconds = 10;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_badgeCleared) return;
    _badgeCleared = true;
    context.read<NotificationState>().clearChatBadge();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
      _requeueScheduled = false;
      _ignoredSessionId = null;
      _activePendingSessionId = null;
    });
  }

  void _startCountdown() {
    if (_countdownTimer != null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown <= 1) {
        timer.cancel();
        final String? sessionId = _activePendingSessionId;
        setState(() {
          _countdown = 0;
          _timeoutReached = true;
        });
        _closePendingOverlay(ignoreSession: true);
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _timeoutReached = false);
          _scheduleRequeueOnce(context.read<AppState>());
        });
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  void _stopCountdownTimerOnly() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _closePendingOverlay({bool ignoreSession = false}) {
    _stopCountdownTimerOnly();
    if (ignoreSession && _activePendingSessionId != null) {
      _ignoredSessionId = _activePendingSessionId;
    }
    _activePendingSessionId = null;
  }

  void _scheduleRequeueOnce(AppState state) {
    if (_requeueScheduled || state.stopMatchEnabled) return;
    _requeueScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!state.stopMatchEnabled) {
        await state.enterAutoMatchQueue();
        if (mounted) {
          setState(() => _queueActive = true);
        }
      }
    });
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const DistanceFilterWidget(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);

    final me = state.meOrNull;
    final bool profileComplete = me != null && state.isProfileReady(me);
    final MatchSession? session = state.activeAutoMatchSession;
    final MatchSession? latestSession = state.latestAutoMatchSession;
    final bool hasPending =
        session != null && session.status == MatchStatus.pending;
    final bool hasAccepted =
        session != null && session.status == MatchStatus.accepted;
    final bool showSearching =
        _queueActive || state.autoMatchState == AutoMatchState.searching;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F4),
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: l.chatTitle, onOpenSettings: _openSettingsSheet),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (!profileComplete) {
                    return _ProfileCompletionPrompt(
                      title: l.profileCompleteTitle,
                      actionLabel: l.profileCompleteAction,
                      onComplete: () => context.go('/home/profile'),
                    );
                  }

                  if (_timeoutReached) {
                    _navigating = false;
                    _stopCountdownTimerOnly();
                    return _ChatTimeoutState(title: l.queueTimeout);
                  }

                  if (latestSession != null &&
                      (latestSession.status == MatchStatus.rejected ||
                          latestSession.status == MatchStatus.expired)) {
                    if (_handledEndSessionId != latestSession.id) {
                      _handledEndSessionId = latestSession.id;
                      if (_activePendingSessionId == latestSession.id) {
                        _closePendingOverlay(ignoreSession: true);
                      }
                      _scheduleRequeueOnce(state);
                    }
                  }

                  if (hasAccepted) {
                    if (session!.chatRoomId != null &&
                        session.chatRoomId!.trim().isNotEmpty) {
                      if (!_navigating) {
                        _navigating = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          context.go('/home/chat/room/${session.chatRoomId}');
                          setState(() {
                            _activePendingSessionId = null;
                            _ignoredSessionId = null;
                            _requeueScheduled = false;
                            _handledEndSessionId = null;
                          });
                        });
                      }
                      return _ChatWaitingState(
                        title: l.chatWaitingTitle,
                        subtitle: l.chatWaitingSubtitle,
                      );
                    }
                  }

                  if (!showSearching && !hasPending) {
                    _stopCountdownTimerOnly();
                    return _ChatSearchingState(
                      emoji: l.chatSearchingEmoji,
                      title: l.queueSearchingTitle,
                      subtitle: l.queueSearchingSubtitle,
                      countdownText: null,
                      showConnect: true,
                      connectLabel: l.queueConnect,
                      onConnect: _enterMatchingQueue,
                      showStop: false,
                      stopLabel: l.queueStop,
                      onStop: () {},
                    );
                  }

                  final Widget base = _ChatSearchingState(
                    emoji: l.chatSearchingEmoji,
                    title: l.queueSearchingTitle,
                    subtitle: l.queueSearchingSubtitle,
                    countdownText: null,
                    showConnect: !showSearching,
                    connectLabel: l.queueConnect,
                    onConnect: _enterMatchingQueue,
                    showStop: showSearching,
                    stopLabel: l.queueStop,
                    onStop: () async {
                      await state.stopAutoMatchQueue();
                      if (!mounted) return;
                      setState(() => _queueActive = false);
                    },
                  );

                  if (!hasPending || session == null) {
                    _stopCountdownTimerOnly();
                    return base;
                  }
                  if (_ignoredSessionId == session.id) {
                    _stopCountdownTimerOnly();
                    return base;
                  }

                  if (_activePendingSessionId != session.id) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (_activePendingSessionId == session.id ||
                          _ignoredSessionId == session.id) {
                        return;
                      }
                      setState(() {
                        _activePendingSessionId = session.id;
                        _countdown = _queueDurationSeconds;
                        _timeoutReached = false;
                      });
                      _startCountdown();
                    });
                  }

                  final String myId = state.me.id;
                  final String opponentId = session.userA == myId
                      ? session.userB
                      : session.userA;

                  return FutureBuilder<Profile?>(
                    future: state.fetchProfile(opponentId),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      return Stack(
                        children: [
                          base,
                          if (profile != null)
                            _MatchPendingOverlay(
                              profile: profile,
                              countdownSeconds: _countdown,
                              totalSeconds: _queueDurationSeconds,
                              remainingLabel: l.queueRemainingTime(
                                _countdown.toString(),
                              ),
                              acceptLabel: l.queueAccept,
                              declineLabel: l.queueDecline,
                              onAccept: () async {
                                _closePendingOverlay();
                                final uid = state.me.id;
                                await FirebaseFirestore.instance
                                    .collection('match_sessions')
                                    .doc(session.id)
                                    .set({
                                      'responses.$uid': 'accepted',
                                    }, SetOptions(merge: true));
                              },
                              onDecline: () async {
                                _closePendingOverlay(ignoreSession: true);
                                final uid = state.me.id;
                                await FirebaseFirestore.instance
                                    .collection('match_sessions')
                                    .doc(session.id)
                                    .set({
                                      'responses.$uid': 'rejected',
                                    }, SetOptions(merge: true));
                                _scheduleRequeueOnce(state);
                              },
                            ),
                        ],
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

/* ───────────────────────── UI Components ───────────────────────── */

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onOpenSettings;
  const _Header({required this.title, required this.onOpenSettings});

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
            onPressed: onOpenSettings,
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
  final bool showStop;
  final String stopLabel;
  final VoidCallback onStop;

  const _ChatSearchingState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.countdownText,
    required this.showConnect,
    required this.connectLabel,
    required this.onConnect,
    required this.showStop,
    required this.stopLabel,
    required this.onStop,
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
          Text(countdownText!, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
        ],
        if (showConnect)
          FilledButton(onPressed: onConnect, child: Text(connectLabel)),
        if (showStop) ...[
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onStop, child: Text(stopLabel)),
        ],
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
      children: [Text(title, style: const TextStyle(fontSize: 18))],
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
    final double progress = (countdownSeconds / totalSeconds).clamp(0.0, 1.0);
    final String ageText = profile.age > 0 ? profile.age.toString() : '';
    final String nameText = profile.name.trim();
    final String title = ageText.isEmpty ? nameText : '$nameText, $ageText';
    final String intro = profile.bio.trim();

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD36E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'MATCH FOUND!',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                    backgroundImage:
                        profile.photoUrl != null &&
                            profile.photoUrl!.trim().isNotEmpty
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child:
                        profile.photoUrl == null ||
                            profile.photoUrl!.trim().isEmpty
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 16)),
                if (intro.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    intro,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
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
