import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'state/locale_state.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    await Firebase.initializeApp();
  }

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
