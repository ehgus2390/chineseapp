import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // firebase_options.dart 쓰고 있으면 옵션 넣어줘도 됨
  runApp(const KkiriApp());
}

class KkiriApp extends StatelessWidget {
  const KkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kkiri',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        home: const RootScreen(),
      ),
    );
  }
}

/// 로그인 여부에 따라 LoginScreen 또는 MainScreen 띄우는 루트
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (appState.user == null) {
          return const LoginScreen();
        } else {
          return const MainScreen();
        }
      },
    );
  }
}
