// lib/screens/tabs/chat_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../state/app_state.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String _anonName(String uid) {
    if (uid.length <= 6) return 'Anon-$uid';
    return 'Anon-${uid.substring(0, 6)}';
  }

  Future<void> _handleJoin(ChatProvider chat, String uid) async {
    await chat.joinRandomRoom(uid);
  }

  Future<void> _handleLeave(ChatProvider chat, String uid) async {
    await chat.leaveRoom(uid);
  }

  Future<void> _handleProfileTap(
    AppState appState,
    String targetId,
    bool profileAllowed,
  ) async {
    await appState.refreshUser();
    final me = appState.user;
    if (me == null) return;

    if (!me.emailVerified) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verify email to view profiles'),
          content: const Text(
            'Chats stay anonymous. To open someone\'s profile, verify your email first. You can request a verification link below.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                await appState.sendVerificationEmail();
                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Resend email'),
            ),
          ],
        ),
      );
      return;
    }

    if (!profileAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This user keeps their profile hidden until they verify their email.')),
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Basic profile'),
        content: Text('Profile visibility unlocked. User id: $targetId'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(ChatProvider chat, AppState appState) async {
    final user = appState.user;
    if (user == null || !chat.isInRoom) return;
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    await chat.sendRoomMessage(
      userId: user.uid,
      text: text,
      displayName: _anonName(user.uid),
      profileAllowed: user.emailVerified,
    );
    _messageCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final chat = context.watch<ChatProvider>();
    final user = appState.user;

    if (user == null) {
      return const Center(child: Text('Sign in to join anonymous chat rooms.'));
    }

    return Column(
      children: [
        _VicinityCard(chat: chat),
        if (!user.emailVerified)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are chatting anonymously. Verify your email to unlock profile viewing.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: appState.sendVerificationEmail,
                  child: const Text('Verify'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat.isInRoom
                      ? 'You are in a ${chat.vicinityKm.toStringAsFixed(1)} km vicinity room'
                      : 'Join a random open room near ${chat.vicinityKm.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (chat.isInRoom)
                OutlinedButton.icon(
                  onPressed: () => _handleLeave(chat, user.uid),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Leave'),
                )
              else
                ElevatedButton.icon(
                  onPressed: chat.isJoining ? null : () => _handleJoin(chat, user.uid),
                  icon: chat.isJoining
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shuffle),
                  label: const Text('Join random room'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: chat.isInRoom
              ? _MessagesList(
                  chat: chat,
                  onProfileTap: (uid, profileAllowed) =>
                      _handleProfileTap(appState, uid, profileAllowed),
                  myUid: user.uid,
                )
              : const Center(
                  child: Text('Join a room to start chatting with nearby foreigners anonymously.'),
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    enabled: chat.isInRoom,
                    decoration: const InputDecoration(
                      hintText: 'Say hi to your new group...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(chat, appState),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: chat.isInRoom ? () => _sendMessage(chat, appState) : null,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VicinityCard extends StatelessWidget {
  const _VicinityCard({required this.chat});

  final ChatProvider chat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Match by vicinity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Set how far you want to match with other foreigners. Rooms are grouped by vicinity and filled randomly.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: chat.vicinityKm,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${chat.vicinityKm.toStringAsFixed(1)} km',
              onChanged: chat.isJoining ? null : chat.updateVicinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.chat,
    required this.onProfileTap,
    required this.myUid,
  });

  final ChatProvider chat;
  final void Function(String uid, bool profileAllowed) onProfileTap;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: chat.currentRoomMessagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No messages yet. Say hello!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final text = data['text'] as String? ?? '';
            final senderId = data['userId'] as String? ?? '';
            final name = data['displayName'] as String? ?? 'Anon';
            final profileAllowed = data['profileAllowed'] as bool? ?? false;
            final isMe = senderId == myUid;

            return Card(
              color: isMe ? Colors.indigo.shade50 : null,
              child: ListTile(
                title: Text(name),
                subtitle: Text(text),
                trailing: isMe
                    ? null
                    : TextButton(
                        onPressed: () => onProfileTap(senderId, profileAllowed),
                        child: const Text('View profile'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
