import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';
import '../widgets/distance_filter_widget.dart';
import '../models/profile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F4),
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
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const DistanceFilterWidget(),
            Expanded(
              child: StreamBuilder<List<Profile>>(
                stream: state.watchNearbyUsers(),
                initialData: const <Profile>[],
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        l.chatEmpty,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  final list = snapshot.data ?? <Profile>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        l.chatEmpty,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final distance = state.distanceKmTo(p);
                      final distanceLabel =
                          distance == null ? '' : ' · ${distance.toStringAsFixed(1)}km';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (p.photoUrl == null || p.photoUrl!.isEmpty)
                              ? null
                              : NetworkImage(p.photoUrl!),
                          child: (p.photoUrl == null || p.photoUrl!.isEmpty)
                              ? const Icon(Icons.person, color: Colors.black)
                              : null,
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          '${p.age}$distanceLabel',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        onTap: () async {
                          final matchId = await state.ensureChatRoom(p.id);
                          if (!context.mounted) return;
                          context.go('/home/chat/room/$matchId');
                        },
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
