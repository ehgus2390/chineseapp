import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'tabs/chat_list_screen.dart';
import 'tabs/friends_screen.dart';
import 'tabs/profile_screen.dart';
import 'tabs/board_screen.dart';
import 'settings/settings_screen.dart';
import 'search/search_screen.dart';
import 'map/nearby_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // 채팅 탭 기본
  final _pages = const [
    ProfileScreen(),
    FriendsScreen(),
    ChatListScreen(),
    BoardScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = List<Widget>.from(_pages);
    // ③ 채팅과 ④ 게시판 사이에 지도 탭 추가 (원하시는 위치로 조정)
    pages.insert(3, NearbyMapScreen()); // index 3에 지도 삽입

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kkiri'),
        centerTitle: true,
        actions: [/* ...검색/설정 동일... */],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 프로필'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '친구'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),   // ✅ 추가
          BottomNavigationBarItem(icon: Icon(Icons.article), label: '게시판'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: '더보기'),
        ],
      ),
    );
  }
}
