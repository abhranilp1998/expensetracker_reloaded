import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
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

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

/// Root widget: wires Riverpod theme state into MaterialApp and routes.
class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'Ledgerly',
      theme: AppThemeData.lightTheme(theme.accent),
      darkTheme: AppThemeData.darkTheme(theme.accent),
      themeMode: theme.mode,
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
