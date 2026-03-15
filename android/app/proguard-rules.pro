# android/app/proguard-rules.pro

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# OpenDialer
-keep class com.opendialer.** { *; }

# Telecom
-keep class android.telecom.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# sqflite
-keep class io.flutter.plugins.sqflite.** { *; }

# Gson / JSON (if used)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
