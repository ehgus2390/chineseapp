import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return _fromEnv(
        apiKey: const String.fromEnvironment(
          'FIREBASE_WEB_API_KEY',
          defaultValue: '',
        ),
        appId: const String.fromEnvironment(
          'FIREBASE_WEB_APP_ID',
          defaultValue: '',
        ),
        messagingSenderId: const String.fromEnvironment(
          'FIREBASE_WEB_MESSAGING_SENDER_ID',
          defaultValue: '',
        ),
        projectId: const String.fromEnvironment(
          'FIREBASE_WEB_PROJECT_ID',
          defaultValue: '',
        ),
        authDomain: const String.fromEnvironment(
          'FIREBASE_WEB_AUTH_DOMAIN',
          defaultValue: '',
        ),
        storageBucket: const String.fromEnvironment(
          'FIREBASE_WEB_STORAGE_BUCKET',
          defaultValue: '',
        ),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _fromEnv(
          apiKey: const String.fromEnvironment(
            'FIREBASE_ANDROID_API_KEY',
            defaultValue: '',
          ),
          appId: const String.fromEnvironment(
            'FIREBASE_ANDROID_APP_ID',
            defaultValue: '',
          ),
          messagingSenderId: const String.fromEnvironment(
            'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
            defaultValue: '',
          ),
          projectId: const String.fromEnvironment(
            'FIREBASE_ANDROID_PROJECT_ID',
            defaultValue: '',
          ),
          storageBucket: const String.fromEnvironment(
            'FIREBASE_ANDROID_STORAGE_BUCKET',
            defaultValue: '',
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _fromEnv(
          apiKey: const String.fromEnvironment(
            'FIREBASE_IOS_API_KEY',
            defaultValue: '',
          ),
          appId: const String.fromEnvironment(
            'FIREBASE_IOS_APP_ID',
            defaultValue: '',
          ),
          messagingSenderId: const String.fromEnvironment(
            'FIREBASE_IOS_MESSAGING_SENDER_ID',
            defaultValue: '',
          ),
          projectId: const String.fromEnvironment(
            'FIREBASE_IOS_PROJECT_ID',
            defaultValue: '',
          ),
          storageBucket: const String.fromEnvironment(
            'FIREBASE_IOS_STORAGE_BUCKET',
            defaultValue: '',
          ),
          iosBundleId: const String.fromEnvironment(
            'FIREBASE_IOS_BUNDLE_ID',
            defaultValue: '',
          ),
          iosClientId: const String.fromEnvironment(
            'FIREBASE_IOS_CLIENT_ID',
            defaultValue: '',
          ),
          appGroupId: const String.fromEnvironment(
            'FIREBASE_IOS_APP_GROUP_ID',
            defaultValue: '',
          ),
        );
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _fromEnv(
          apiKey: const String.fromEnvironment(
            'FIREBASE_DESKTOP_API_KEY',
            defaultValue: '',
          ),
          appId: const String.fromEnvironment(
            'FIREBASE_DESKTOP_APP_ID',
            defaultValue: '',
          ),
          messagingSenderId: const String.fromEnvironment(
            'FIREBASE_DESKTOP_MESSAGING_SENDER_ID',
            defaultValue: '',
          ),
          projectId: const String.fromEnvironment(
            'FIREBASE_DESKTOP_PROJECT_ID',
            defaultValue: '',
          ),
          storageBucket: const String.fromEnvironment(
            'FIREBASE_DESKTOP_STORAGE_BUCKET',
            defaultValue: '',
          ),
        );
      default:
        return null;
    }
  }

  static FirebaseOptions? _fromEnv({
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String projectId,
    String authDomain = '',
    String databaseURL = '',
    String storageBucket = '',
    String iosBundleId = '',
    String iosClientId = '',
    String androidClientId = '',
    String appGroupId = '',
  }) {
    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      databaseURL: databaseURL.isEmpty ? null : databaseURL,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
      iosClientId: iosClientId.isEmpty ? null : iosClientId,
      androidClientId: androidClientId.isEmpty ? null : androidClientId,
      appGroupId: appGroupId.isEmpty ? null : appGroupId,
    );
  }
}
