import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/message.dart';
import '../state/app_state.dart';

class ChatRoomScreen extends StatefulWidget {
  final String threadId;
  const ChatRoomScreen({super.key, required this.threadId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final thread = state.threadById(widget.threadId);
    final partner = state.getById(thread.friendId);
    final msgs = state.chat.getMessages(widget.threadId);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(partner.avatarUrl)),
            const SizedBox(width: 12),
            Text(partner.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final Message m = msgs[msgs.length - 1 - i];
                final bool isMe = m.senderId == state.me.id;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
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
                      hintText: l.messagePlaceholder,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = ctrl.text.trim();
                    if (text.isEmpty) return;
                    state.sendMessage(widget.threadId, text);
                    ctrl.clear();
                    setState(() {});
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
