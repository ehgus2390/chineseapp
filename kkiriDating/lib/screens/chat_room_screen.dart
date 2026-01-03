import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/message.dart';

class ChatRoomScreen extends StatefulWidget {
  final String matchId;
  const ChatRoomScreen({super.key, required this.matchId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final msgs = state.chat.getMessages(widget.matchId);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final Message m = msgs[msgs.length - 1 - i];
                final isMe = m.senderId == state.me.id;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.pink.shade50 : Colors.grey.shade200,
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
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = ctrl.text.trim();
                    if (text.isEmpty) return;
                    state.chat.send(widget.matchId, state.me.id, text);
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
