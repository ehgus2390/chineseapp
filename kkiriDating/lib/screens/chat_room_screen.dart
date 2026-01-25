import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../state/notification_state.dart';
import '../models/message.dart';
import '../l10n/app_localizations.dart';
import '../models/profile.dart';

class ChatRoomScreen extends StatefulWidget {
  final String matchId;
  const ChatRoomScreen({super.key, required this.matchId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ctrl = TextEditingController();
  bool _guideChecked = false;
  bool _badgeCleared = false;
  bool _firstMessageLogged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_guideChecked) return;
    _guideChecked = true;
    if (!_badgeCleared) {
      _badgeCleared = true;
      context.read<NotificationState>().clearChatBadge();
    }
    final state = context.read<AppState>();
    final l = AppLocalizations.of(context);
    state.ensureFirstMessageGuide(widget.matchId, l.firstMessageGuide);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.chatTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: l.chatExit,
            onPressed: () async {
              await state.exitChatRoom(widget.matchId);
              if (!context.mounted) return;
              context.go('/home/chat');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: state.chat.watchMessages(widget.matchId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l.chatError,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snapshot.data ?? <Message>[];
                final bool hasUserMessage = msgs.any(
                  (m) => m.senderId == state.me.id,
                );
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
                          final Message m = msgs[msgs.length - 1 - i];
                          final isSystem = m.senderId == 'system';
                          final isMe = m.senderId == state.me.id;
                          if (isSystem) {
                            return Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  m.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            );
                          }
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.pink.shade50
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(m.text),
                            ),
                          );
                        },
                      ),
                    ),
                    if (!hasUserMessage)
                      _SuggestionChips(
                        matchId: widget.matchId,
                        onSelect: (text) {
                          ctrl.text = text;
                          ctrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: ctrl.text.length),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      hintText: l.chatInputHint,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = ctrl.text.trim();
                    if (text.isEmpty) return;
                    if (!_firstMessageLogged) {
                      _firstMessageLogged = true;
                      final parts = widget.matchId.split('_');
                      final otherId = parts.firstWhere(
                        (id) => id != state.me.id,
                        orElse: () => '',
                      );
                      if (otherId.isNotEmpty) {
                        state.logFirstMessageSent(
                          sessionId: widget.matchId,
                          otherUserId: otherId,
                        );
                      }
                    }
                    await state.chat.send(widget.matchId, state.me.id, text);
                    ctrl.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final String matchId;
  final ValueChanged<String> onSelect;

  const _SuggestionChips({required this.matchId, required this.onSelect});

  List<String> _suggestionsFromProfiles(
    AppLocalizations l,
    Profile me,
    Profile other,
  ) {
    final shared = other.interests.where(me.interests.contains).toList();
    if (shared.isEmpty) return <String>[];
    final interest = shared.first;
    return l.firstMessageSuggestions
        .split('|')
        .map((s) => s.replaceAll('{interest}', interest))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);
    final me = state.meOrNull;
    if (me == null) return const SizedBox.shrink();
    final parts = matchId.split('_');
    final otherId = parts.firstWhere((id) => id != me.id, orElse: () => '');
    if (otherId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Profile?>(
      future: state.fetchProfile(otherId),
      builder: (context, snapshot) {
        final other = snapshot.data;
        if (other == null) return const SizedBox.shrink();
        final suggestions = _suggestionsFromProfiles(l, me, other);
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Wrap(
            spacing: 8,
            children: suggestions
                .map(
                  (text) => ActionChip(
                    label: Text(text),
                    onPressed: () => onSelect(text),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
