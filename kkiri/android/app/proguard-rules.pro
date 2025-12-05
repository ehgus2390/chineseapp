# Flutter and Firebase keep rules for release builds
# Keep Flutter's generated entry points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase Auth and Firestore models
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Kotlin coroutines and serialization
-dontwarn kotlinx.coroutines.**
