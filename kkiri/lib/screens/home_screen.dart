import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 2;

  void _onTap(int i) {
    setState(() => _index = i);
    switch (i) {
      case 0:
        context.go('/home/profile');
        break;
      case 1:
        context.go('/home/friends');
        break;
      case 2:
        context.go('/home/chat');
        break;
      case 3:
        context.go('/home/map');
        break;
      case 4:
        context.go('/home/board');
        break;
      case 5:
        context.go('/home/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '친구'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: '게시판'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
