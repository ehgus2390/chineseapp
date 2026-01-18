import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_room_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';
import 'state/locale_state.dart';
import 'state/notification_state.dart';

class KkiriApp extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const KkiriApp({super.key, required this.scaffoldMessengerKey});

  @override
  State<KkiriApp> createState() => _KkiriAppState();
}

class _KkiriAppState extends State<KkiriApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(context.read<AppState>());
  }

  GoRouter _buildRouter(AppState state) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: state,
      redirect: (context, routerState) {
        final bool loggedIn = state.isLoggedIn;
        final String location = routerState.matchedLocation;
        final bool loggingIn = location == '/login';

        if (!loggedIn) {
          return loggingIn ? null : '/login';
        }
        if (loggingIn) {
          return '/home/discover';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
        ShellRoute(
          builder: (context, state, child) {
            return _HomeShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home/discover',
              builder: (_, __) => const RecommendationScreen(),
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
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleState>().locale;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      title: 'Kkiri Dating',
      locale: locale,
      scaffoldMessengerKey: widget.scaffoldMessengerKey,
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
    final location = GoRouter.of(context).location;
    final unreadChatCount = context.watch<NotificationState>().unreadChatCount;

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
            // Clear badge only when user explicitly enters chat.
            context.read<NotificationState>().clearChatBadge();
            context.go('/home/chat');
            break;
          case 2:
            context.go('/home/profile');
            break;
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.explore),
          label: l.tabRecommend,
        ),
        NavigationDestination(
          icon: _Badge(
            show: unreadChatCount > 0,
            child: const Icon(Icons.chat_bubble),
          ),
          label: l.tabChat,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person),
          label: l.tabProfile,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final bool show;
  final Widget child;

  const _Badge({required this.show, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeShell extends StatelessWidget {
  final Widget child;

  const _HomeShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).location;
    if (location.startsWith('/home/chat/room')) {
      return Scaffold(body: child, bottomNavigationBar: _BottomNav());
    }
    int currentIndex = 0;
    if (location.startsWith('/home/chat')) currentIndex = 1;
    if (location.startsWith('/home/profile')) currentIndex = 2;
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          RecommendationScreen(),
          ChatListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}
