import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/discover_screen.dart';
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
      initialLocation: '/login',
      refreshListenable: state,
      redirect: (context, routerState) {
        final bool loggedIn = state.isLoggedIn;
        final bool onboarded = state.isOnboarded;
        final String location = routerState.matchedLocation;
        final bool loggingIn = location == '/login';
        final bool onboarding = location == '/onboarding';

        if (!loggedIn) {
          return loggingIn ? null : '/login';
        }
        if (!onboarded) {
          return onboarding ? null : '/onboarding';
        }
        if (loggingIn || onboarding) {
          return '/home/discover';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const AuthScreen(),
        ),
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
      title: 'Kkiri Dating',
      locale: locale,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE94D8A),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F3F4),
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/home/chat')) currentIndex = 1;
    if (location.startsWith('/home/profile')) currentIndex = 2;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/home/discover');
            break;
          case 1:
            context.go('/home/chat');
            break;
          case 2:
            context.go('/home/profile');
            break;
        }
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.explore), label: l.tabRecommend),
        NavigationDestination(icon: const Icon(Icons.chat_bubble), label: l.tabChat),
        NavigationDestination(icon: const Icon(Icons.person), label: l.tabProfile),
      ],
    );
  }
}
