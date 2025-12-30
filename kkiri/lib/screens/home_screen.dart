import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/location_provider.dart';
import 'package:provider/provider.dart';
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
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<LocationProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final location =
        GoRouter.of(context).routeInformationProvider.value.uri.toString();
    final currentIndex = _locationToIndex(location);
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: t?.profile ?? 'Profile'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.group), label: t?.friends ?? 'Friends'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat), label: t?.chat ?? 'Chat'),
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: t?.map ?? 'Map'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.article), label: t?.board ?? 'Board'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings), label: t?.settings ?? 'Settings'),
        ],
      ),
    );
  }
}
