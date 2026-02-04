import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/profile.dart';
import '../../state/app_state.dart';

class LikesInboxPage extends StatefulWidget {
  const LikesInboxPage({super.key});

  @override
  State<LikesInboxPage> createState() => _LikesInboxPageState();
}

class _LikesInboxPageState extends State<LikesInboxPage> {
  bool _markedSeen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_markedSeen) return;
    _markedSeen = true;
    context.read<AppState>().markLikesSeen();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.likesInboxTitle)),
      body: StreamBuilder(
        stream: state.watchLikesInbox(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l.chatError));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(l.likesInboxEmpty));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final String fromUid = (data['fromUid'] ?? '').toString();
              return FutureBuilder<Profile?>(
                future: state.fetchProfile(fromUid),
                builder: (context, profileSnap) {
                  final profile = profileSnap.data;
                  if (profile == null) {
                    return const ListTile(
                      title: Text(''),
                      leading: CircleAvatar(child: Icon(Icons.person)),
                    );
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          profile.photoUrl != null &&
                              profile.photoUrl!.isNotEmpty
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child:
                          profile.photoUrl == null || profile.photoUrl!.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text('${profile.name}, ${profile.age}'),
                    subtitle: Text(profile.country),
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
