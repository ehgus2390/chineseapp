import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extensions.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = <String>[
    '/home/chat',
    '/home/discover',
    '/home/map',
    '/home/matches',
    '/home/profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final loc = context.read<LocationProvider>();
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        await loc.startAutoUpdate(uid);
      }
    });
  }

  void _onTap(int index) {
    if (index < 0 || index >= _tabs.length) return;
    final target = _tabs[index];

    final current = GoRouter.of(context)
        .routeInformationProvider
        .value
        .uri
        .toString();

    if (current != target) {
      context.go(target);
    }
  }

  int _locationToIndex(String location) {
    final matchIndex = _tabs.indexWhere((path) => location.startsWith(path));
    return matchIndex == -1 ? 2 : matchIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final currentPath = GoRouter.of(context)
        .routeInformationProvider
        .value
        .uri
        .toString();

    final currentIndex = _locationToIndex(currentPath);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: l10n.chatTab),
          NavigationDestination(icon: const Icon(Icons.favorite_outline), label: l10n.discoverTab),
          NavigationDestination(icon: const Icon(Icons.map_outlined), label: l10n.mapTab),
          NavigationDestination(icon: const Icon(Icons.favorite), label: l10n.matchesTab),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.profileTab),
        ],
      ),
    );
  }
}
