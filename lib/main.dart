import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensetracker_reloaded/routes/app_routes.dart';
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'dart:async';
import 'package:expensetracker_reloaded/services/notification_service.dart';
import 'package:expensetracker_reloaded/services/sms_service.dart';
import 'package:expensetracker_reloaded/data/db/db_instance.dart';
import 'package:expensetracker_reloaded/data/migration/prefs_migration.dart';
import 'package:expensetracker_reloaded/data/repositories/transaction_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  // One-time legacy SharedPreferences -> SQLite migration.
  await PrefsMigration.run(
    await SharedPreferences.getInstance(),
    TransactionRepository(appDatabase),
  );

  // Load saved animation preference
  await AnimationPreferencesService.loadAnimationType();

  // Initialize theme service
  await ThemeService.initialize();

  // Single SMS listener (foreground + background) and one-time inbox import.
  await SmsService.start();
  unawaited(SmsService.importInboxOnce());

  runApp(const ExpenseTrackerApp());
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
    final colorName = ThemeService.availableColors.keys.firstWhere(
      (k) => ThemeService.availableColors[k] == color,
      orElse: () => 'green',
    );
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
