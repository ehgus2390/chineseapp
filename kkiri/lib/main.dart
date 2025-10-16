import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성됨
import 'app.dart';
import 'state/app_state.dart';
import 'state/locale_state.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localeState = LocaleState();
  await localeState.load();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => localeState),
      ChangeNotifierProvider(create: (_) => AppState()..bootstrap()),
    ],
    child: const KkiriApp(),
  ));
}
