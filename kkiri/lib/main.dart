import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ 추가
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/location_provider.dart';
import 'providers/locale_provider.dart';
import 'services/post_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'state/app_state.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        Provider<PostService>(create: (_) => PostService()),
      ],
      child: const KkiriApp(),
    ),
  );
}

class KkiriApp extends StatefulWidget {
  const KkiriApp({super.key});

  @override
  State<KkiriApp> createState() => _KkiriAppState();
}

class _KkiriAppState extends State<KkiriApp> {
  String? _lastUidApplied;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();
    final localeProv = context.watch<LocaleProvider>();

    final uid = auth.currentUser?.uid;

    // ✅ uid가 바뀌었을 때만 1회 실행 (rebuild 폭탄 방지)
    if (uid != null && uid != _lastUidApplied && !localeProv.isManuallySet) {
      _lastUidApplied = uid;

      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .then((snap) {
        final lang = snap.data()?['mainLanguage'];
        if (lang is String && lang.isNotEmpty) {
          localeProv.setLocaleFromProfile(lang);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'Kkiri',
      locale: localeProv.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
        Locale('zh'),
        Locale('es'),
        Locale('vi'),
        Locale('hi'),
        Locale('bn'),
        Locale('fil'),
      ],
      localizationsDelegates: const [
        // ✅ gen-l10n 생성 delegate
        AppLocalizations.delegate,

        // ✅ Flutter 기본 로컬라이제이션
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return appState.user == null ? const LoginScreen() : const MainScreen();
  }
}
