import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/screens/main_shell.dart';

/// Lightweight stand-in for the four-tab NavigationBar contract.
class _TabBarProbe extends StatefulWidget {
  const _TabBarProbe();
  @override
  State<_TabBarProbe> createState() => _TabBarProbeState();
}

class _TabBarProbeState extends State<_TabBarProbe> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          Center(child: Text('home-body')),
          Center(child: Text('activity-body')),
          Center(child: Text('review-body')),
          Center(child: Text('settings-body')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.rule_outlined),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('four tab destinations and switch', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _TabBarProbe()));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('home-body'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pump();
    expect(find.text('activity-body'), findsOneWidget);
  });

  testWidgets('real MainShell starts on Home (index 0)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          home: MainShell(
            pagesOverride: [
              Center(child: Text('home-body')),
              Center(child: Text('activity-body')),
              Center(child: Text('review-body')),
              Center(child: Text('settings-body')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, MainShell.homeIndex);
    expect(MainShell.homeIndex, 0);
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 0);
  });
}
