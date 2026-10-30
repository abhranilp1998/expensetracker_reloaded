import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/routes/animation_showcase.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/screens/main_shell.dart';
import 'package:expensetracker_reloaded/screens/onboarding/onboarding_flow.dart';
import 'package:expensetracker_reloaded/screens/demo_page.dart';
import 'package:expensetracker_reloaded/screens/profile_page.dart';
import 'package:expensetracker_reloaded/screens/event_logs_page.dart';
import 'package:expensetracker_reloaded/screens/till_now_page.dart';
import 'package:expensetracker_reloaded/screens/review_queue_page.dart';
import 'package:expensetracker_reloaded/screens/learned_rules_page.dart';
import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart';
import 'package:expensetracker_reloaded/screens/history_page.dart';
import 'package:expensetracker_reloaded/screens/inbox_scan_page.dart';
import 'package:expensetracker_reloaded/screens/today_insights_page.dart';
import 'package:expensetracker_reloaded/screens/debug_hub_page.dart';
import 'package:expensetracker_reloaded/services/user_prefs_service.dart';

/// Named route constants; see [onGenerateRoute].
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String comprehensiveSettings = '/settings-comprehensive';
  static const String history = '/history';
  static const String demo = '/demo';
  static const String profile = '/profile';
  static const String animationShowcase = '/animation-showcase';
  static const String eventLogs = '/event-logs';
  static const String tillNow = '/till-now';
  static const String review = '/review';
  static const String learnedRules = '/learned-rules';
  static const String todayInsights = '/today-insights';
  static const String debugHub = '/debug-hub';

  /// SMS inbox import (consent, progress, summary). Argument: `true` when
  /// opened from onboarding.
  static const String inboxScan = '/inbox-scan';
}

Route<dynamic> createRoute(Widget page) {
  return AnimationVariants.createRoute(page);
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.welcome:
      return createRoute(const BootstrapGate());
    case AppRoutes.onboarding:
      return createRoute(const OnboardingFlow());
    case AppRoutes.home:
      return createRoute(const MainShell());
    case AppRoutes.comprehensiveSettings:
      return createRoute(const ComprehensiveSettingsPage());
    case AppRoutes.history:
      return createRoute(const HistoryPage());
    case AppRoutes.demo:
      return createRoute(const DemoPage());
    case AppRoutes.profile:
      return createRoute(const ProfilePage());
    case AppRoutes.animationShowcase:
      return createRoute(const AnimationPreview());
    case AppRoutes.eventLogs:
      return createRoute(const EventLogsPage());
    case AppRoutes.tillNow:
      return createRoute(const TillNowPage());
    case AppRoutes.review:
      return createRoute(const ReviewQueuePage());
    case AppRoutes.learnedRules:
      return createRoute(const LearnedRulesPage());
    case AppRoutes.todayInsights:
      return createRoute(const TodayInsightsPage());
    case AppRoutes.inboxScan:
      return createRoute(
        InboxScanPage(fromOnboarding: settings.arguments == true),
      );
    case AppRoutes.debugHub:
      return createRoute(const DebugHubPage());
    default:
      return createRoute(const BootstrapGate());
  }
}

/// Routes `/` to onboarding or home based on persisted flag.
@visibleForTesting
class BootstrapGate extends StatefulWidget {
  const BootstrapGate();

  @override
  State<BootstrapGate> createState() => BootstrapGateState();
}

class BootstrapGateState extends State<BootstrapGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    final done = await UserPrefsService.isOnboardingCompleted();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacementNamed(done ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    // Back is ignored while we decide where to go (it used to exit the app
    // before Home loaded, skipping the "Leaving already?" dialog).
    return const PopScope(
      canPop: false,
      child: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
