import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/recommendation_provider.dart';
import '../state/eligible_profiles_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/profile_card.dart';
import 'package:kkiri/l10n/app_localizations.dart';
import '../models/profile.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final Set<String> _dismissedIds = <String>{};
  DateTime? _lastSeenRefresh;
  int _selectedTab = 0;

  void _dismiss(Profile profile, bool liked) {
    if (liked) {
      context.read<AppState>().like(profile);
    } else {
      context.read<AppState>().pass(profile);
    }
    setState(() => _dismissedIds.add(profile.id));
  }

  Future<void> _startChat(Profile target) async {
    final state = context.read<AppState>();
    final me = state.meOrNull;
    final bool profileComplete = me != null && state.isProfileReady(me);
    if (!profileComplete) {
      if (!mounted) return;
      context.go('/home/profile');
      return;
    }
    if (!state.isProfileReady(target)) return;
    final session = await state.ensureMatchSession(
      otherUserId: target.id,
      mode: MatchMode.direct,
    );
    await state.logEvent(
      type: 'direct_initiated',
      sessionId: session.id,
      mode: 'direct',
      otherUserId: target.id,
    );
    await state.ensureChatRoomForSession(session.id);
    if (!mounted) return;
    context.go('/home/chat/room/${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final recommendations = context.watch<RecommendationProvider>();
    final me = state.meOrNull;
    final bool profileComplete = me != null && state.isProfileReady(me);
    if (_lastSeenRefresh != recommendations.lastUpdatedAt) {
      _lastSeenRefresh = recommendations.lastUpdatedAt;
      _dismissedIds.clear();
    }

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    l.appTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    l.discoverTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.black54),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => recommendations.refreshRecommendations(
                      reason: RefreshReason.manual,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l.refreshRecommendations,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                StreamBuilder<int>(
                  stream: context
                      .read<NotificationProvider>()
                      .unseenCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return IconButton(
                      icon: _BadgeIcon(
                        show: count > 0,
                        child: const Icon(Icons.notifications),
                      ),
                      onPressed: () => context.go('/home/notifications'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Flexible(
                child: _HeaderTab(
                  label: l.tabRecommend,
                  selected: _selectedTab == 0,
                  onTap: () {
                    setState(() => _selectedTab = 0);
                    recommendations.setMode(RecommendationTab.recommend);
                    recommendations.refreshRecommendations(
                      reason: RefreshReason.manual,
                    );
                  },
                ),
              ),
              Flexible(
                child: _HeaderTab(
                  label: l.tabNearby,
                  selected: _selectedTab == 1,
                  onTap: () {
                    setState(() => _selectedTab = 1);
                    recommendations.setMode(RecommendationTab.nearby);
                    recommendations.refreshRecommendations(
                      reason: RefreshReason.manual,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _RecommendationBody(
            profileComplete: profileComplete,
            recommendations: recommendations,
            dismissedIds: _dismissedIds,
            onStartChat: _startChat,
            onDismiss: _dismiss,
            distanceFor: state.distanceKmTo,
            showNearbyOnly: _selectedTab == 1,
            me: me,
          ),
        ),
      ],
    );
  }
}

class _RecommendationBody extends StatelessWidget {
  final bool profileComplete;
  final RecommendationProvider recommendations;
  final Set<String> dismissedIds;
  final void Function(Profile target) onStartChat;
  final void Function(Profile profile, bool liked) onDismiss;
  final double? Function(Profile profile) distanceFor;
  final bool showNearbyOnly;
  final Profile? me;

  const _RecommendationBody({
    required this.profileComplete,
    required this.recommendations,
    required this.dismissedIds,
    required this.onStartChat,
    required this.onDismiss,
    required this.distanceFor,
    required this.showNearbyOnly,
    required this.me,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!profileComplete) {
      return _ProfileCompletionPrompt(
        title: l.profileCompleteTitle,
        actionLabel: l.profileCompleteAction,
        onComplete: () => context.go('/home/profile'),
      );
    }
    if (recommendations.isLoading && recommendations.recommendations.isEmpty) {
      return _MatchingProgress(
        title: l.matchingSearchingTitle,
        subtitle: l.matchingSearchingSubtitle,
      );
    }
    final list = recommendations.recommendations;
    final filteredByTab = list;
    if (filteredByTab.isEmpty) {
      return _NoMatchState(
        title: l.noMatchTitle,
        subtitle: l.noMatchSubtitle,
        actionLabel: l.noMatchAction,
        onAction: () => context.go('/home/profile'),
      );
    }
    final filtered = filteredByTab
        .where((p) => !dismissedIds.contains(p.id))
        .toList();
    if (filtered.isEmpty) {
      return _NoMatchState(
        title: l.noMatchTitle,
        subtitle: l.noMatchSubtitle,
        actionLabel: l.noMatchAction,
        onAction: () => context.go('/home/profile'),
      );
    }
    final top = filtered.first;
    final next = filtered.length > 1 ? filtered[1] : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l.recommendCardSubtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (next != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Transform.scale(
                      scale: 0.96,
                      child: ProfileCard(
                        profile: next,
                        onLike: () {},
                        onPass: () {},
                        onChat: () => onStartChat(next),
                        distanceKm: distanceFor(next),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Dismissible(
                  key: ValueKey(top.id),
                  direction: DismissDirection.horizontal,
                  background: _SwipeHint(
                    color: Colors.green.withOpacity(0.2),
                    icon: Icons.favorite,
                    alignment: Alignment.centerLeft,
                  ),
                  secondaryBackground: _SwipeHint(
                    color: Colors.red.withOpacity(0.2),
                    icon: Icons.close,
                    alignment: Alignment.centerRight,
                  ),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      onDismiss(top, false);
                    } else {
                      onDismiss(top, true);
                    }
                  },
                  child: ProfileCard(
                    profile: top,
                    onLike: () => onDismiss(top, true),
                    onPass: () => onDismiss(top, false),
                    onChat: () => onStartChat(top),
                    distanceKm: distanceFor(top),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HeaderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : Colors.black38;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final bool show;
  final Widget child;

  const _BadgeIcon({required this.show, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwipeHint extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Alignment alignment;

  const _SwipeHint({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: color,
      child: Icon(icon, color: Colors.white, size: 48),
    );
  }
}

class _MatchingProgress extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MatchingProgress({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _NoMatchState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
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
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
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
            FilledButton(onPressed: onComplete, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
