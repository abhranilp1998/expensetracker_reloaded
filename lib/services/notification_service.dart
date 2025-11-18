// Notification service placeholder.
// The project currently uses a global `flutterLocalNotificationsPlugin` in
// `main.dart` and `home_dashboard.dart`. To centralize notification logic,
// move initialization and show methods into this service.

// Example API:
// class NotificationService {
//   Future<void> initialize();
//   Future<void> showExpenseNotification(double amount, double total, {bool background = false});
// }


import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';
import '../main.dart';

class NotificationService {
  static Future<void> showExpenseNotification(
    double amount,
    double dailyTotal,
  ) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: 'Notifications for expense tracking',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Expense Detected',
      '₹${amount.toStringAsFixed(2)} spent — Daily: ₹${dailyTotal.toStringAsFixed(2)}',
      details,
    );
  }

  static Future<void> showDailyResetNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: 'Notifications for expense tracking',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      1,
      'Daily Reset',
      'Your expense tracking has been reset for the new day.',
      details,
    );
  }

  static Future<void> showCustomNotification(
    String title,
    String body,
  ) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: 'Notifications for expense tracking',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      2,
      title,
      body,
      details,
    );
  }
}