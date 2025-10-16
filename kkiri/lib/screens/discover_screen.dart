import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/profile_card.dart';
import '../l10n/app_localizations.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final list = state.sortedCandidates();

    if (list.isEmpty) {
      return Center(child: Text(l.discoverEmpty));
    }

    final p = list.first;
    return ProfileCard(
      profile: p,
      onLike: () => state.like(p),
      onPass: () => state.pass(p),
    );
  }
}
