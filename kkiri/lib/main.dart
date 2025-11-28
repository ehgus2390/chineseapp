import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/match_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map/nearby_map_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tabs/chat_list_screen.dart';
import 'screens/tabs/discover_screen.dart';
import 'screens/tabs/matches_screen.dart';
import 'screens/tabs/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
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
          ChangeNotifierProvider(create: (_) => MatchProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const KkiriApp(),
      ),
    );
  } catch (e) {
    runApp(FirebaseInitErrorApp(error: e));
  }
}

class FirebaseInitErrorApp extends StatelessWidget {
  final Object error;
  const FirebaseInitErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Firebase 초기화에 실패했습니다.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '프로젝트 설정을 확인하고 다시 시도해주세요. 환경 변수나 google-services 설정이 필요할 수 있습니다.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '$error',
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KkiriApp extends StatelessWidget {
  const KkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
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
          // Chat is the primary MVP experience. After a successful sign-in,
          // keep users in the chat-first flow instead of jumping to discover.
          return '/home/chat';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
        ShellRoute(
          builder: (context, state, child) => HomeScreen(child: child),
          routes: [
            GoRoute(path: '/home/discover', builder: (_, __) => const DiscoverScreen()),
            GoRoute(path: '/home/matches', builder: (_, __) => const MatchesScreen()),
            GoRoute(path: '/home/chat', builder: (_, __) => const ChatListScreen()),
            GoRoute(path: '/home/map', builder: (_, __) => const NearbyMapScreen()),
            GoRoute(path: '/home/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(path: '/home/settings', builder: (_, __) => const SettingsScreen()),
          ],
        ),
      ],
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.teal,
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      textTheme: ThemeData().textTheme.apply(letterSpacingDelta: 0.1),
    );

    return MaterialApp.router(
      title: 'LinguaCircle',
      theme: baseTheme,
      locale: settings.locale,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
