import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../providers/notification_provider.dart';
import '../../state/app_state.dart';

class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  bool _markedSeen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_markedSeen) return;
    _markedSeen = true;
    context.read<NotificationProvider>().markAllSeen();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.notificationsInboxTitle)),
      body: StreamBuilder(
        stream: notifications.inboxStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l.chatError));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(l.notificationsInboxEmpty));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final type = (data['type'] ?? '').toString();
              final fromUid = (data['fromUid'] ?? '').toString();
              final refId = (data['refId'] ?? '').toString();

              return FutureBuilder<Profile?>(
                future: fromUid.isEmpty ? null : state.fetchProfile(fromUid),
                builder: (context, profileSnap) {
                  final profileName = profileSnap.data?.name ?? fromUid;
                  String title = l.notificationsSystemText;
                  if (type == 'like') {
                    title = l.notificationsLikeText(profileName);
                  } else if (type == 'match') {
                    title = l.notificationsMatchText;
                  } else if (type == 'chat') {
                    title = l.notificationsChatText;
                  }

                  return ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      if (type == 'like') {
                        context.go('/home/likes');
                        return;
                      }
                      if (type == 'match') {
                        if (refId.isEmpty) return;
                        final matchSnap = await FirebaseFirestore.instance
                            .collection('match_sessions')
                            .doc(refId)
                            .get();
                        final data = matchSnap.data() ?? {};
                        final String chatRoomId = (data['chatRoomId'] ?? '')
                            .toString();
                        if (chatRoomId.isNotEmpty) {
                          if (!context.mounted) return;
                          context.go('/home/chat/room/$chatRoomId');
                        } else {
                          if (!context.mounted) return;
                          context.go('/home/chat');
                        }
                        return;
                      }
                      if (type == 'chat') {
                        if (refId.isEmpty) return;
                        if (!context.mounted) return;
                        context.go('/home/chat/room/$refId');
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
