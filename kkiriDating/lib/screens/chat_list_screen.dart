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
    final me = state.meOrNull;
    final bool profileComplete = me != null && state.isProfileReady(me);

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
            if (profileComplete) const DistanceFilterWidget(),
            Expanded(
              child: profileComplete
                  ? StreamBuilder<List<Profile>>(
                      stream: state.watchNearbyUsers(),
                      initialData: const <Profile>[],
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint(
                              'watchNearbyUsers error: ${snapshot.error}');
                          return Center(
                            child: Text(
                              'Something went wrong. Please try again.',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final list = snapshot.data ?? const <Profile>[];
                        if (list.isEmpty) {
                          return const Center(
                            child: Text(
                              '조건에 맞는 프로필이 없습니다',
                              style: TextStyle(color: Colors.black54),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final p = list[i];
                            final distance = state.distanceKmTo(p);
                            final distanceLabel = distance == null
                                ? ''
                                : ' · ${distance.toStringAsFixed(1)}km';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    (p.photoUrl == null || p.photoUrl!.isEmpty)
                                        ? null
                                        : NetworkImage(p.photoUrl!),
                                child: (p.photoUrl == null ||
                                        p.photoUrl!.isEmpty)
                                    ? const Icon(Icons.person,
                                        color: Colors.black)
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
                                final matchId =
                                    await state.ensureChatRoom(p.id);
                                if (!context.mounted) return;
                                context.go('/home/chat/room/$matchId');
                              },
                            );
                          },
                        );
                      },
                    )
                  : _ProfileCompletionPrompt(
                      onComplete: () => context.go('/home/profile'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionPrompt extends StatelessWidget {
  final VoidCallback onComplete;

  const _ProfileCompletionPrompt({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '프로필을 완성해야 추천을 받을 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onComplete,
              child: const Text('프로필 완성하기'),
            ),
          ],
        ),
      ),
    );
  }
}
