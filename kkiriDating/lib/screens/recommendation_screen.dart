import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/profile_card.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final Set<String> _dismissedIds = <String>{};

  void _dismiss(Profile profile, bool liked) {
    if (liked) {
      context.read<AppState>().like(profile);
    } else {
      context.read<AppState>().pass(profile);
    }
    setState(() => _dismissedIds.add(profile.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  l.appTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                Text(
                  l.discoverTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.black54),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => context.go('/home/profile'),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              _HeaderTab(label: l.tabRecommend, selected: true),
              _HeaderTab(label: l.tabNearby, selected: false),
              _HeaderTab(label: l.tabFeed, selected: false),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Profile>>(
            stream: state.watchCandidates(),
            initialData: const <Profile>[],
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(l.discoverEmpty));
              }
              final list = snapshot.data ?? <Profile>[];
              if (list.isEmpty) {
                return Center(child: Text(l.discoverEmpty));
              }
              final filtered =
                  list.where((p) => !_dismissedIds.contains(p.id)).toList();
              if (filtered.isEmpty) {
                return Center(child: Text(l.discoverEmpty));
              }
              final top = filtered.first;
              final next = filtered.length > 1 ? filtered[1] : null;

              return Stack(
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
                            distanceKm: state.distanceKmTo(next),
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
                          _dismiss(top, false);
                        } else {
                          _dismiss(top, true);
                        }
                      },
                      child: ProfileCard(
                        profile: top,
                        onLike: () => _dismiss(top, true),
                        onPass: () => _dismiss(top, false),
                        distanceKm: state.distanceKmTo(top),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _HeaderTab({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : Colors.black38;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
            ),
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
