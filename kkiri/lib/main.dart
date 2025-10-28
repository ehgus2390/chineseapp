import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/location_provider.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map/nearby_map_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tabs/board_screen.dart';
import 'screens/tabs/chat_list_screen.dart';
import 'screens/tabs/friends_screen.dart';
import 'screens/tabs/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const KkiriApp(),
    ),
  );
}

class KkiriApp extends StatelessWidget {
  const KkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final router = GoRouter(
      initialLocation: '/home/chat',
      refreshListenable: auth,
      redirect: (context, state) {
        final isLoggedIn = auth.currentUser != null;
        final loggingIn = state.matchedLocation == '/sign-in';
        if (!isLoggedIn) {
          return loggingIn ? null : '/sign-in';
        }
        if (loggingIn) {
          return '/home/chat';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
        ShellRoute(
          builder: (context, state, child) => HomeScreen(child: child),
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
