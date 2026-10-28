import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';

/// Single notification entry point. Safe to call from the background SMS
/// isolate: it lazily initializes the plugin per isolate.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'expense_tracker',
      'Expense Notifications',
      channelDescription: 'Notifications for detected transactions',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> initialize() async {
    if (_initialized) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// [key] makes the id stable per transaction so notifications stack
  /// instead of overwriting each other.
  /// Does nothing when Settings > Notifications is off (bug #11).
  static Future<void> show(String title, String body, {String? key}) async {
    if (!await AppSettings.notificationsEnabled()) return;
    await initialize();
    final id =
        (key ?? '$title$body${DateTime.now().microsecondsSinceEpoch}')
            .hashCode &
        0x7fffffff;
    await _plugin.show(id, title, body, _details);
  }
}
