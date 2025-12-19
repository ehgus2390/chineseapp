import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = <String>[
    '/home/profile',
    '/home/friends',
    '/home/chat',
    '/home/map',
    '/home/board',
    '/home/settings',
  ];

  void _onTap(int index) {
    if (index < 0 || index >= _tabs.length) return;
    final target = _tabs[index];

    final current =
        GoRouter.of(context).routeInformationProvider.value.uri.toString();

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
    final t = AppLocalizations.of(context)!;
    final currentIndex = _locationToIndex(GoRouter.of(context).location);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: t.profile),
          BottomNavigationBarItem(icon: const Icon(Icons.group), label: t.friends),
          BottomNavigationBarItem(icon: const Icon(Icons.chat), label: t.chat),
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: t.map),
          BottomNavigationBarItem(icon: const Icon(Icons.article), label: t.board),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings), label: t.settings),
        ],
      ),
    );
  }
}
