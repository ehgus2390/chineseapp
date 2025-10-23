import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/post_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/locale_provider.dart';

import 'screens/auth/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

// 만약 flutterfire configure를 사용했다면 자동생성된 firebase_options.dart 사용 가능
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // 있으면 주석 해제
  );
  runApp(const KkiriApp());
}

class KkiriApp extends StatelessWidget {
  const KkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..listenAuthState()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (_, localeProv, __) {
          return MaterialApp(
            title: 'Kkiri',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: localeProv.locale,
            supportedLocales: const [
              Locale('ko'),
              Locale('en'),
              Locale('zh'),
              Locale('hi'),
              Locale('ja'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: Consumer<AuthProvider>(
              builder: (_, auth, __) {
                if (auth.isLoading) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                return auth.currentUser == null ? const SignInScreen() : const HomeScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
