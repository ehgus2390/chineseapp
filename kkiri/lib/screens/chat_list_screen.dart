import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppState state = context.watch<AppState>();
    final threads = state.threads;

    if (threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            l.chatListEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (BuildContext context, int index) {
        final thread = threads[index];
        final partner = state.getById(thread.friendId);
        final lastMessage = thread.lastMessage;

        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(partner.avatarUrl)),
          title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(lastMessage ?? l.startChat, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(
            state.formatTime(thread.updatedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () => context.go('/home/chat/room/${thread.id}'),
        );
      },
    );
  }
}
