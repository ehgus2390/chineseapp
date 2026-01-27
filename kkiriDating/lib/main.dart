import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'state/locale_state.dart';
import 'state/eligible_profiles_provider.dart';
import 'state/recommendation_provider.dart';
import 'state/notification_state.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_navigation.dart';
import 'services/analytics_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final localeState = LocaleState();
  try {
    await localeState.load();
  } catch (e, st) {
    debugPrint('Locale init failed: $e');
    debugPrintStack(stackTrace: st);
  }

  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final appState = AppState();
  await appState.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => localeState),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => NotificationState()),
        ChangeNotifierProxyProvider<AppState, UserProvider>(
          create: (context) => UserProvider(context.read<AppState>()),
          update: (_, appState, provider) {
            provider ??= UserProvider(appState);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppState, NotificationProvider>(
          create: (context) => NotificationProvider(context.read<AppState>()),
          update: (_, appState, provider) {
            provider ??= NotificationProvider(appState);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppState, EligibleProfilesProvider>(
          create: (_) => EligibleProfilesProvider(),
          update: (_, appState, provider) {
            provider!.updateFromAppState(appState);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<
          EligibleProfilesProvider,
          RecommendationProvider
        >(
          create: (context) => RecommendationProvider(
            eligibleProvider: context.read<EligibleProfilesProvider>(),
          ),
          update: (_, eligible, provider) {
            provider!.updateEligibleProvider(eligible);
            return provider;
          },
        ),
      ],
      child: _NotificationListenerHost(
        scaffoldMessengerKey: scaffoldMessengerKey,
        child: KkiriApp(scaffoldMessengerKey: scaffoldMessengerKey),
      ),
    ),
  );
}

class _NotificationListenerHost extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  const _NotificationListenerHost({
    required this.scaffoldMessengerKey,
    required this.child,
  });

  @override
  State<_NotificationListenerHost> createState() =>
      _NotificationListenerHostState();
}

class _NotificationListenerHostState extends State<_NotificationListenerHost> {
  late final AnalyticsLogger _analytics;

  @override
  void initState() {
    super.initState();
    _analytics = AnalyticsLogger(FirebaseFirestore.instance);
    _handleInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final appState = context.read<AppState>();
      if (appState.meOrNull?.notificationsEnabled == false) return;
      context.read<NotificationState>().clearChatBadge();
      final type = message.data['type']?.toString() ?? 'unknown';
      final resolvedRoute = _routeForNotification(message.data);
      if (resolvedRoute == null) {
        _analytics.logEvent(
          type: 'notification_invalid',
          notificationType: type,
          userId: appState.meOrNull?.id ?? '',
        );
      }
      final targetRoute = resolvedRoute ?? '/home/chat';
      _analytics.logEvent(
        type: 'notification_opened',
        notificationType: type,
        userId: appState.meOrNull?.id ?? '',
        targetRoute: targetRoute,
      );
      handleNotificationNavigation(context, message.data);
    });
    FirebaseMessaging.onMessage.listen((message) {
      final type = message.data['type']?.toString();
      final appState = context.read<AppState>();
      if (appState.meOrNull?.notificationsEnabled == false) return;
      final userId = appState.meOrNull?.id ?? '';
      if (type == null) {
        _analytics.logEvent(
          type: 'notification_invalid',
          notificationType: 'unknown',
          userId: userId,
        );
        return;
      }
      _analytics.logEvent(
        type: 'notification_received',
        notificationType: type,
        userId: userId,
      );
      final notifications = context.read<NotificationState>();
      final l = AppLocalizations.of(context);
      if (type == 'match_accepted') {
        // Foreground UX: toast + badge update.
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(l.notificationMatchAcceptedToast),
            action: SnackBarAction(
              label: l.notificationViewAction,
              onPressed: () {
                context.read<NotificationState>().clearChatBadge();
                final resolvedRoute = _routeForNotification(message.data);
                if (resolvedRoute == null) {
                  _analytics.logEvent(
                    type: 'notification_invalid',
                    notificationType: type,
                    userId: userId,
                  );
                }
                _analytics.logEvent(
                  type: 'in_app_notification_clicked',
                  notificationType: type,
                  userId: userId,
                  targetRoute: resolvedRoute ?? '/home/chat',
                );
                handleNotificationNavigation(context, message.data);
              },
            ),
          ),
        );
        notifications.incrementChatBadge();
      } else if (type == 'new_message') {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(l.notificationNewMessageToast),
            action: SnackBarAction(
              label: l.notificationViewAction,
              onPressed: () {
                context.read<NotificationState>().clearChatBadge();
                final resolvedRoute = _routeForNotification(message.data);
                if (resolvedRoute == null) {
                  _analytics.logEvent(
                    type: 'notification_invalid',
                    notificationType: type,
                    userId: userId,
                  );
                }
                _analytics.logEvent(
                  type: 'in_app_notification_clicked',
                  notificationType: type,
                  userId: userId,
                  targetRoute: resolvedRoute ?? '/home/chat',
                );
                handleNotificationNavigation(context, message.data);
              },
            ),
          ),
        );
        notifications.incrementChatBadge();
      }
    });
  }

  Future<void> _handleInitialMessage() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial == null) return;
    final appState = context.read<AppState>();
    if (appState.meOrNull?.notificationsEnabled == false) return;
    context.read<NotificationState>().clearChatBadge();
    final type = initial.data['type']?.toString() ?? 'unknown';
    final resolvedRoute = _routeForNotification(initial.data);
    if (resolvedRoute == null) {
      _analytics.logEvent(
        type: 'notification_invalid',
        notificationType: type,
        userId: appState.meOrNull?.id ?? '',
      );
    }
    final targetRoute = resolvedRoute ?? '/home/chat';
    _analytics.logEvent(
      type: 'notification_opened',
      notificationType: type,
      userId: appState.meOrNull?.id ?? '',
      targetRoute: targetRoute,
    );
    handleNotificationNavigation(context, initial.data);
  }

  String? _routeForNotification(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'match_accepted') {
      final chatRoomId = data['chatRoomId']?.toString();
      if (chatRoomId == null || chatRoomId.isEmpty) return null;
      return '/home/chat/room/$chatRoomId';
    }
    if (type == 'new_message') {
      final roomId = data['roomId']?.toString();
      if (roomId == null || roomId.isEmpty) return null;
      return '/home/chat/room/$roomId';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
