import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/screens/comprehensive_settings_page.dart';
import 'package:expensetracker_reloaded/screens/history_page.dart';
import 'package:expensetracker_reloaded/screens/home_dashboard.dart';
import 'package:expensetracker_reloaded/screens/review_queue_page.dart';

/// Bottom tabs: Home, Activity, Review, Settings. Side drawer lives on each tab.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(reviewQueueProvider).value?.length ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeDashboard(),
          HistoryPage(asTab: true),
          ReviewQueuePage(asTab: true),
          ComprehensiveSettingsPage(asTab: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
    );
  }
}
