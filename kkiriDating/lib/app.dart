import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:kkiri/l10n/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_room_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_completion_screen.dart';
import 'screens/notifications/notifications_inbox_page.dart';
import 'screens/likes/likes_inbox_page.dart';
import 'screens/admin_moderation_screen.dart';
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
    final appState = context.read<AppState>();
    _router = _buildRouter(appState);
  }

  GoRouter _buildRouter(AppState state) {
    return GoRouter(
      initialLocation: state.isLoggedIn ? '/home/discover' : '/login',
      refreshListenable: state,
      redirect: (context, routerState) {
        if (routerState.matchedLocation == '/') {
          return state.isLoggedIn ? '/home/discover' : '/login';
        }
        if (state.authFlowInProgress) {
          return routerState.matchedLocation == '/login' ? null : '/login';
        }
        final bool profileComplete = state.isProfileComplete;
        final bool loggedIn = state.isLoggedIn;
        final String location = routerState.matchedLocation;
        final bool loggingIn = location == '/login';
        final bool completingProfile = location == '/profile-completion';
        final bool profileRoute = location == '/home/profile';

        if (!loggedIn) {
          return loggingIn ? null : '/login';
        }
        if (profileComplete && completingProfile) {
          return '/home/discover';
        }
        if (!profileComplete && !completingProfile && !profileRoute) {
          return '/profile-completion';
        }
        if (location == '/admin' && !state.isAdmin) {
          return '/home/profile';
        }
        if (loggingIn) {
          return '/home/discover';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminModerationScreen()),
        GoRoute(
          path: '/profile-completion',
          builder: (_, __) => const ProfileCompletionScreen(),
        ),
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
            GoRoute(
              path: '/home/notifications',
              builder: (_, __) => const NotificationsInboxPage(),
            ),
            GoRoute(
              path: '/home/likes',
              builder: (_, __) => const LikesInboxPage(),
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
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.toString();
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
    final location = GoRouterState.of(context).uri.toString();
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


