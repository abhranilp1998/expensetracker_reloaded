import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature toggles from Settings > Feature Settings (bug #11).
///
/// Each flag is persisted in SharedPreferences and mirrored in a static
/// field so hot paths (route builder, haptics, logger) read it without I/O.
/// [load] runs in main() before runApp; Settings calls [set] on toggle.
class AppSettings {
  AppSettings._();

  static const notificationsKey = 'pref_notifications';
  static const hapticKey = 'pref_haptic_feedback';
  static const animationsKey = 'pref_animations_enabled';
  static const eventLoggingKey = 'pref_event_logging';

  /// Vibrate on taps (nav bar, Add, Save, Delete).
  static bool haptics = true;

  /// Page transition animations. Off = instant page changes.
  static bool animations = true;

  /// Local activity log (Debug > Event logs). Never uploaded.
  static bool eventLogging = true;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    haptics = p.getBool(hapticKey) ?? true;
    animations = p.getBool(animationsKey) ?? true;
    eventLogging = p.getBool(eventLoggingKey) ?? true;
  }

  /// Persists one flag and applies it immediately.
  static Future<void> set(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
    switch (key) {
      case hapticKey:
        haptics = value;
      case animationsKey:
        animations = value;
      case eventLoggingKey:
        eventLogging = value;
    }
  }

  /// Read fresh from disk: the background SMS isolate has its own memory, so
  /// it must not rely on the static fields above.
  static Future<bool> notificationsEnabled() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return p.getBool(notificationsKey) ?? true;
  }
}

/// Tap feedback that respects the Haptic Feedback setting.
class Haptics {
  Haptics._();
  static void tap() {
    if (AppSettings.haptics) HapticFeedback.selectionClick();
  }
}
