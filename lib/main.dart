import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const ExpenseTrackerApp());
}

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  if (message.body != null) {
    final regex = RegExp(r'(?:rs\.?|inr)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false);
    final match = regex.firstMatch(message.body!);
    if (match != null) {
      try {
        final amount = double.parse(match.group(1)!.replaceAll(',', ''));
        final prefs = await SharedPreferences.getInstance();
        final currentTotal = prefs.getDouble('todayTotal') ?? 0.0;
        final newTotal = currentTotal + amount;
        await prefs.setDouble('todayTotal', newTotal);

        // Show notification for background message
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'expense_tracker',
          'Expense Notifications',
          channelDescription: 'Notifications for expense tracking',
          importance: Importance.max,
          priority: Priority.high,
        );
        
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        
        await flutterLocalNotificationsPlugin.show(
          0,
          'New Expense Detected (Background)',
          '₹${amount.toStringAsFixed(2)} spent\nDaily total: ₹${newTotal.toStringAsFixed(2)}',
          platformChannelSpecifics,
        );
      } catch (e) {
        debugPrint('Error in background handler: $e');
      }
    }
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: onGenerateRoute,
    );
  }
}