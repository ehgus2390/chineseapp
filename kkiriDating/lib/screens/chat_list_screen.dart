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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 253, 253),
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
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _FilterChip(label: l.chatFilterAll, selected: true),
                  _FilterChip(label: l.chatFilterLikes, selected: false),
                  _FilterChip(label: l.chatFilterNew, selected: false),
                ],
              ),
            ),
            Expanded(
              child: state.matches.isEmpty
                  ? Center(
                      child: Text(
                        l.chatEmpty,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.matches.length,
                      itemBuilder: (_, i) {
                        final match = state.matches[i];
                        final partnerId = match.userIds.firstWhere(
                          (id) => id != state.me.id,
                          orElse: () => '',
                        );
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
                                backgroundImage: avatar.isEmpty
                                    ? null
                                    : NetworkImage(avatar),
                                child: avatar.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              title: Text(
                                profile?.name ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                match.lastMessage.isEmpty
                                    ? l.startChat
                                    : match.lastMessage,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                _formatDate(match.lastMessageAt),
                                style: const TextStyle(color: Colors.white54),
                              ),
                              onTap: () =>
                                  context.go('/home/chat/room/${match.id}'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.month}/${date.day}';
}
