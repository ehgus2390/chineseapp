import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final currentIndex = _locationToIndex(GoRouter.of(context).location);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Board'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
