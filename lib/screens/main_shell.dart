import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart';
import 'package:expensetracker_reloaded/screens/history_page.dart';
import 'package:expensetracker_reloaded/screens/home_dashboard.dart';
import 'package:expensetracker_reloaded/screens/review_queue_page.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';

/// Bottom tabs: Home, Activity, Review, Settings. Side drawer lives on each tab.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.pagesOverride});

  /// Home is always index 0 and is where every launch lands.
  static const int homeIndex = 0;

  /// Test hook: replaces the four tab bodies.
  @visibleForTesting
  final List<Widget>? pagesOverride;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(reviewQueueProvider).value?.length ?? 0;
    final index = ref.watch(shellTabProvider);
    final tabs = ref.read(shellTabProvider.notifier);

    // Back (bug #7): on Activity/Review/Settings go to Home; on Home let the
    // system handle it (leave the app).
    return PopScope(
      canPop: index == MainShell.homeIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) tabs.select(MainShell.homeIndex);
      },
      child: Scaffold(
        body: IndexedStack(
          index: index,
          children:
              widget.pagesOverride ??
              const [
                HomeDashboard(),
                HistoryPage(asTab: true),
                ReviewQueuePage(asTab: true),
                ComprehensiveSettingsPage(asTab: true),
              ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            Haptics.tap();
            tabs.select(i);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pending > 0,
                label: Text(pending > 99 ? '99+' : '$pending'),
                child: const Icon(Icons.rule_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pending > 0,
                label: Text(pending > 99 ? '99+' : '$pending'),
                child: const Icon(Icons.rule),
              ),
              label: 'Review',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
