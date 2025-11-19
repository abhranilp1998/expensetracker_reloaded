import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
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

  // Load saved animation preference
  await AnimationPreferencesService.loadAnimationType();

  // Initialize theme service
  await ThemeService.initialize();

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

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();

  static _ExpenseTrackerAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ExpenseTrackerAppState>();
  }
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  late ThemeMode _themeMode;
  late MaterialColor _accentColor;

  @override
  void initState() {
    super.initState();
    _themeMode = ThemeService.getCurrentTheme();
    _accentColor = ThemeService.getCurrentAccentColor();
  }

  void setTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    // Fire and forget, but ensure it's saved
    unawaited(ThemeService.setTheme(mode));
  }

  void setAccentColor(MaterialColor color) {
    setState(() {
      _accentColor = color;
    });
    final colorName = ThemeService.availableColors.keys
        .firstWhere((k) => ThemeService.availableColors[k] == color, orElse: () => 'green');
    // Fire and forget, but ensure it's saved
    unawaited(ThemeService.setAccentColor(colorName));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: AppThemeData.lightTheme(_accentColor),
      darkTheme: AppThemeData.darkTheme(_accentColor),
      themeMode: _themeMode,
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
