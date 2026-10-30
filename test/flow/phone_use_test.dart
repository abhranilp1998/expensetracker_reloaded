import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/screens/main_shell.dart';
import 'package:expensetracker_reloaded/screens/profile_page.dart';
import 'package:expensetracker_reloaded/screens/today_insights_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _shell(ProviderContainer c) => UncontrolledProviderScope(
  container: c,
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
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'userName': 'Abhranil'}));

  testWidgets('Back on a secondary tab goes Home (#7)', (t) async {
    final c = ProviderContainer(
      overrides: [
        reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    await t.pumpWidget(_shell(c));
    await t.tap(find.text('Settings'));
    await t.pump();
    expect(c.read(shellTabProvider), 3);
    final popped = await t.binding.handlePopRoute();
    await t.pump();
    expect(popped, isTrue); // handled by PopScope, app stays open
    expect(c.read(shellTabProvider), MainShell.homeIndex);
    final stack = t.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, 0);
  });

  testWidgets('Back on Home asks; Stay keeps app, Quit exits', (t) async {
    final c = ProviderContainer(
      overrides: [
        reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    final calls = <MethodCall>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    await t.pumpWidget(_shell(c));
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Leaving already?'), findsOneWidget);
    expect(find.text('More insights await.'), findsOneWidget);
    await t.tap(find.byKey(const Key('leave-stay')));
    await t.pumpAndSettle();
    expect(find.text('Leaving already?'), findsNothing);
    expect(find.text('home-body'), findsOneWidget);
    expect(calls.where((m) => m.method == 'SystemNavigator.pop'), isEmpty);

    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('leave-quit')));
    await t.pumpAndSettle();
    expect(calls.where((m) => m.method == 'SystemNavigator.pop'), isNotEmpty);
  });

  testWidgets('See all style tab switch via provider (#18)', (t) async {
    final c = ProviderContainer(
      overrides: [
        reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    await t.pumpWidget(_shell(c));
    c.read(shellTabProvider.notifier).select(1);
    await t.pump();
    final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets(
    'Profile: empty name shows error, rename updates provider (#5, #6)',
    (t) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ProfilePage()),
        ),
      );
      await t.pumpAndSettle();
      expect(await c.read(userNameProvider.future), 'Abhranil');
      await t.enterText(find.byKey(const Key('profileName')), '   ');
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('userName'),
        'Abhranil',
      );
      await t.enterText(find.byKey(const Key('profileName')), 'Sunny');
      await t.pumpAndSettle();
      expect(find.text('Enter a name'), findsNothing);
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(c.read(userNameProvider).value, 'Sunny');
    },
  );

  testWidgets(
    'hero shuttle: tall card into short slot does not overflow (#1)',
    (t) async {
      final nav = GlobalKey<NavigatorState>();
      Widget card(double pad) => Container(
        color: Colors.blue,
        padding: EdgeInsets.all(pad),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('a'), SizedBox(height: 60), Text('b'), Text('c')],
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: Scaffold(
            body: Hero(
              tag: 'x',
              flightShuttleBuilder: heroCardShuttle,
              child: card(24),
            ),
          ),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: 40,
                child: Hero(
                  tag: 'x',
                  flightShuttleBuilder: heroCardShuttle,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 20));
      }
      expect(t.takeException(), isNull);
    },
  );
}
