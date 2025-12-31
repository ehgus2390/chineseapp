// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/tabs/chat_page.dart';
import 'screens/tabs/community_page.dart';
import 'screens/tabs/home_page.dart';
import 'screens/tabs/profile_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          HomeScreen(child: child ?? const SizedBox()),
      routes: [
        GoRoute(
          path: '/home/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/home/community',
          builder: (context, state) => const CommunityPage(),
        ),
        GoRoute(
          path: '/home/chat',
          builder: (context, state) => const ChatPage(),
        ),
        GoRoute(
          path: '/home/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
