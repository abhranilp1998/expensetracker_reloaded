import 'package:flutter/foundation.dart';
import 'package:expensetracker_reloaded/routes/animation_showcase.dart';
import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/screens/welcome_screen.dart';
import 'package:expensetracker_reloaded/screens/home_dashboard.dart';
import 'package:expensetracker_reloaded/screens/settings_page.dart';
import 'package:expensetracker_reloaded/screens/history_page.dart';
import 'package:expensetracker_reloaded/screens/demo_page.dart';
import 'package:expensetracker_reloaded/screens/profile_page.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/screens/permissions_page.dart';
import 'package:expensetracker_reloaded/screens/onboarding_permissions_page.dart';
import 'package:expensetracker_reloaded/screens/event_logs_page.dart';
import 'package:expensetracker_reloaded/screens/till_now_page.dart';
import 'package:expensetracker_reloaded/screens/review_queue_page.dart';
import 'package:expensetracker_reloaded/screens/learned_rules_page.dart';
import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart' show ComprehensiveSettingsPage;

/// Global route constants
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String comprehensiveSettings = '/settings-comprehensive';
  static const String history = '/history';
  static const String demo = '/demo';
  static const String profile = '/profile';
  static const String animationShowcase = '/animation-showcase';
  static const String permissions = '/permissions';
  static const String onboardingPermissions = '/onboarding-permissions';
  static const String eventLogs = '/event-logs';
  static const String tillNow = '/till-now';
  static const String review = '/review';
  static const String learnedRules = '/learned-rules';
}

/// Creates an animated route using the currently selected animation variant
/// This respects the global AnimationVariants.currentType setting
Route<dynamic> createRoute(Widget page) {
  return AnimationVariants.createRoute(page);
}

/// Centralized route generator used by `MaterialApp.onGenerateRoute`.
/// This is the single source of truth for all app navigation.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.welcome:
      return createRoute(const WelcomeScreen());
    case AppRoutes.home:
      return createRoute(const HomeDashboard());
    case AppRoutes.settings:
      return createRoute(const SettingsPage());
    case AppRoutes.comprehensiveSettings:
      return createRoute(const ComprehensiveSettingsPage());
    case AppRoutes.history:
      return createRoute(const HistoryPage());
    case AppRoutes.demo when kDebugMode:
      return createRoute(const DemoPage());
    case AppRoutes.profile:
      return createRoute(const ProfilePage());
    case AppRoutes.animationShowcase when kDebugMode:
      return createRoute(const AnimationPreview());
    case AppRoutes.permissions:
      return createRoute(const PermissionsPage());
    case AppRoutes.onboardingPermissions:
      return createRoute(const OnboardingPermissionsPage());
    case AppRoutes.eventLogs:
      return createRoute(const EventLogsPage());
    case AppRoutes.tillNow:
      return createRoute(const TillNowPage());
    case AppRoutes.review:
      return createRoute(const ReviewQueuePage());
    case AppRoutes.learnedRules:
      return createRoute(const LearnedRulesPage());
    default:
      return createRoute(const WelcomeScreen());
  }
}
