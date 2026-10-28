import 'package:flutter/foundation.dart';
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

  /// Payload on "Needs review" notifications; tapping one opens Review.
  static const reviewPayload = 'review';

  /// Payload of the last tapped notification, until the UI consumes it
  /// (MainShell listens and switches to the Review tab).
  static final ValueNotifier<String?> pendingPayload = ValueNotifier(null);

  static Future<void> initialize() async {
    if (_initialized) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: handleResponse,
    );
    _initialized = true;
  }

  /// Tap on a notification while the app is running or in the background.
  static void handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) pendingPayload.value = payload;
  }

  /// Cold start: the app was launched by tapping a notification.
  static Future<void> checkLaunchDetails() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if ((details?.didNotificationLaunchApp ?? false) && response != null) {
        handleResponse(response);
      }
    } catch (e) {
      debugPrint('notification launch details unavailable: $e');
    }
  }

  /// [key] makes the id stable per transaction so notifications stack
  /// instead of overwriting each other.
  /// Does nothing when Settings > Notifications is off (bug #11).
  static Future<void> show(
    String title,
    String body, {
    String? key,
    String? payload,
  }) async {
    if (!await AppSettings.notificationsEnabled()) return;
    await initialize();
    final id =
        (key ?? '$title$body${DateTime.now().microsecondsSinceEpoch}')
            .hashCode &
        0x7fffffff;
    await _plugin.show(id, title, body, _details, payload: payload);
  }
}
