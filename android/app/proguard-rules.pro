# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (needed for R8)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Google Fonts
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
