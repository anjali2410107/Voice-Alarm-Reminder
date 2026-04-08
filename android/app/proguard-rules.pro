# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.runtime.** { *; }

# Our App Classes
-keep class com.example.alarmclock.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Record
-keep class com.llfbandit.record.** { *; }

# Flutter Timezone
-keep class com.whelksoft.flutter_timezone.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Ensure our BroadcastReceiver is not renamed or removed
-keep class com.example.alarmclock.AlarmTriggerReceiver { *; }

# Fix R8 missing class errors for Play Core (not used in this app)
-dontwarn com.google.android.play.core.**
