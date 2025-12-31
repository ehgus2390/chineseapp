import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../firebase_options.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/location_provider.dart';

import '../../screens/home_screen.dart';
import '../../screens/tabs/home_page.dart';
import '../../screens/tabs/community_page.dart';
import '../../screens/tabs/chat_page.dart';
import '../../screens/tabs/profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
    final router = GoRouter(
      initialLocation: '/home/home',
      routes: [
        ShellRoute(
          builder: (_, __, child) => HomeScreen(child: child),
          routes: [
            GoRoute(
              path: '/home/home',
              builder: (_, __) => const HomePage(),
            ),
            GoRoute(
              path: '/home/community',
              builder: (_, __) => const CommunityPage(),
            ),
            GoRoute(
              path: '/home/chat',
              builder: (_, __) => const ChatPage(),
            ),
            GoRoute(
              path: '/home/profile',
              builder: (_, __) => const ProfilePage(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kkiri',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}
