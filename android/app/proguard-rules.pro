# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Firebase and Google Play services
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# FileProvider & AndroidX Core
-keep public class androidx.core.content.FileProvider

# Flutter Deferred Components & Google Play Core
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
