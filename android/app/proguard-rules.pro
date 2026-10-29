# Flutter / plugin keep rules (used if minify/R8 is ever enabled).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# another_telephony
-keep class com.shounakmulay.telephony.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Optional Play Core (deferred components) — not shipped; ignore if minify on.
-dontwarn com.google.android.play.core.**
