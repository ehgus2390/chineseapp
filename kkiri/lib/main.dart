import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/home_screen.dart';
import 'screens/tabs/chat_list_screen.dart';
import 'screens/tabs/friends_screen.dart';
import 'screens/tabs/profile_screen.dart';
import 'screens/tabs/board_screen.dart';
import 'screens/map/nearby_map_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const KkiriApp(),
    ),
  );
}

class KkiriApp extends StatelessWidget {
  const KkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/home/chat',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return HomeScreen(child: child);
          },
          routes: [
            GoRoute(path: '/home/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(path: '/home/friends', builder: (_, __) => const FriendsScreen()),
            GoRoute(path: '/home/chat', builder: (_, __) => const ChatListScreen()),
            GoRoute(path: '/home/map', builder: (_, __) => const NearbyMapScreen()),
            GoRoute(path: '/home/board', builder: (_, __) => const BoardScreen()),
            GoRoute(path: '/home/settings', builder: (_, __) => const SettingsScreen()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Kkiri',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent),
      routerConfig: router,
    );
  }
}
