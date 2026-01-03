import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);
    if (state.matches.isEmpty) {
      return Center(child: Text(l.chatEmpty));
    }
    return ListView.builder(
      itemCount: state.matches.length,
      itemBuilder: (_, i) {
        final match = state.matches[i];
        final partnerId =
            match.userIds.firstWhere((id) => id != state.me.id, orElse: () => '');
        if (partnerId.isEmpty) {
          return const SizedBox.shrink();
        }
        return FutureBuilder(
          future: state.fetchProfile(partnerId),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final avatar = profile?.avatarUrl ?? '';
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: avatar.isEmpty ? null : NetworkImage(avatar),
                child: avatar.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(profile?.name ?? ''),
              subtitle:
                  Text(match.lastMessage.isEmpty ? l.startChat : match.lastMessage),
              onTap: () => context.go('/home/chat/room/${match.id}'),
            );
          },
        );
      },
    );
  }
}
