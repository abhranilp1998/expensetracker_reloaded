import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/screens/welcome_screen.dart';
import 'package:expensetracker_reloaded/screens/home_dashboard.dart';
import 'package:expensetracker_reloaded/screens/settings_page.dart';
import 'package:expensetracker_reloaded/screens/history_page.dart';
import 'package:expensetracker_reloaded/screens/demo_page.dart';
import 'package:expensetracker_reloaded/screens/profile_page.dart';

/// Global route constants
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String demo = '/demo';
  static const String profile = '/profile';
}

/// Creates an animated route with fade + slide transition
/// Used globally for all navigation
Route<dynamic> createRoute(Widget page) {
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
    case AppRoutes.history:
      return createRoute(const HistoryPage());
    case AppRoutes.demo:
      return createRoute(const DemoPage());
    case AppRoutes.profile:
      return createRoute(const ProfilePage());
    default:
      return createRoute(const WelcomeScreen());
  }
}
