import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'profile_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  static const _tabs = [
    '/home/home',
    '/home/community',
    '/home/chat',
    '/home/profile',
  ];

  int _indexFromLocation(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _tabs.indexWhere((e) => loc.startsWith(e));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasUser = appState.user != null;
    if (hasUser && appState.isCheckingCommunityProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasUser && !appState.isCommunityProfileComplete) {
      return const ProfileSetupScreen();
    }

    final index = _indexFromLocation(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
