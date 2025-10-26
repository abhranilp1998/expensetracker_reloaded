import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_dashboard.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Route _createRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOut));
      return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: animation.drive(tween), child: child));
    },
  );
}

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
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return _createRoute(const WelcomeScreen());
          case '/home':
            return _createRoute(const HomeDashboard());
          case '/settings':
            return _createRoute(const SettingsPage());
          case '/history':
            return _createRoute(const HistoryPage());
          case '/demo':
            return _createRoute(const DemoPage());
          case '/profile':
            return _createRoute(const ProfilePage());
          default:
            return _createRoute(const WelcomeScreen());
        }
      },
    );
  }
}