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
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);
  } else {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
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
      textTheme: ThemeData().textTheme,
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
