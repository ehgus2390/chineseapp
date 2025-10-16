import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.matches.isEmpty) {
      return const Center(child: Text('아직 매칭이 없어요'));
    }
    return ListView.builder(
      itemCount: state.matches.length,
      itemBuilder: (_, i) {
        final m = state.matches[i];
        final partner = state.getById(m.partnerId);
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(partner.avatarUrl)),
          title: Text(partner.name),
          subtitle: Text(partner.bio),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/home/chat/room/${m.id}'),
        );
      },
    );
  }
}
