import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_room_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';
import 'state/locale_state.dart';

class KkiriApp extends StatelessWidget {
  const KkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final locale = context.watch<LocaleState>().locale;

    final router = GoRouter(
      initialLocation: state.isOnboarded ? '/home/discover' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              body: child,
              bottomNavigationBar: _BottomNav(),
            );
          },
          routes: [
            GoRoute(
              path: '/home/discover',
              builder: (_, __) => const DiscoverScreen(),
            ),
            GoRoute(
              path: '/home/matches',
              builder: (_, __) => const MatchesScreen(),
            ),
            GoRoute(
              path: '/home/chat',
              builder: (_, __) => const ChatListScreen(),
              routes: [
                GoRoute(
                  path: 'room/:matchId',
                  builder: (ctx, st) =>
                      ChatRoomScreen(matchId: st.pathParameters['matchId']!),
                ),
              ],
            ),
            GoRoute(
              path: '/home/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'Kkiri',
      locale: locale,
      theme: ThemeData(
        colorSchemeSeed: Colors.pink,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/home/matches')) currentIndex = 1;
    if (location.startsWith('/home/chat')) currentIndex = 2;
    if (location.startsWith('/home/profile')) currentIndex = 3;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/home/discover');
            break;
          case 1:
            context.go('/home/matches');
            break;
          case 2:
            context.go('/home/chat');
            break;
          case 3:
            context.go('/home/profile');
            break;
        }
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.explore), label: l.tabDiscover),
        NavigationDestination(icon: const Icon(Icons.favorite), label: l.tabMatches),
        NavigationDestination(icon: const Icon(Icons.chat_bubble), label: l.tabChat),
        NavigationDestination(icon: const Icon(Icons.person), label: l.tabProfile),
      ],
    );
  }
}
