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
    '/home/discover',
    '/home/matches',
    '/home/chat',
    '/home/map',
    '/home/profile',
  ];

  void _onTap(int index) {
    if (index < 0 || index >= _tabs.length) return;
    final target = _tabs[index];
    final router = GoRouter.of(context);
    final currentUri = router.routeInformationProvider.value.uri.toString();

    if (currentUri != target) {
      router.go(target);
    }

  }

  int _locationToIndex(String location) {
    final matchIndex = _tabs.indexWhere((path) => location.startsWith(path));
    return matchIndex == -1 ? 2 : matchIndex;
  }

  @override
  Widget build(BuildContext context) {
    final locationInfo = GoRouter.of(context).routeInformationProvider.value;
    final currentPath = locationInfo.uri.toString();
    final currentIndex = _locationToIndex(currentPath);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '발견'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: '매칭'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '근처'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
