import 'package:expensetracker_reloaded/screens/onboarding/onboarding_flow.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:expensetracker_reloaded/services/user_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Codex 10/10: onboarding must not save an empty name as "User".
void main() {
  test('validateDisplayName matches the Profile rule', () {
    expect(validateDisplayName(''), 'Enter a name');
    expect(validateDisplayName('   '), 'Enter a name');
    expect(validateDisplayName(' Abhranil '), isNull);
  });

  testWidgets('empty name blocks Continue on "About you"', (t) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.initialize();
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingFlow())),
    );
    await t.pumpAndSettle();
    final name = find.byKey(const Key('onboardingName'));
    for (var i = 0; i < 6 && name.evaluate().isEmpty; i++) {
      await t.tap(find.widgetWithText(FilledButton, 'Continue').first);
      await t.pumpAndSettle();
    }
    expect(name, findsOneWidget);

    await t.tap(find.widgetWithText(FilledButton, 'Continue').hitTestable());
    await t.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(name.hitTestable(), findsOneWidget); // still on this page

    await t.enterText(name, 'Abhranil');
    await t.pump();
    expect(find.text('Enter a name'), findsNothing);
    await t.tap(find.widgetWithText(FilledButton, 'Continue').hitTestable());
    await t.pumpAndSettle();
    expect(name.hitTestable(), findsNothing); // moved on
  });

  testWidgets('Skip setup asks for a name and never saves "User"', (t) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.initialize();
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const OnboardingFlow(),
          onGenerateRoute: (s) =>
              MaterialPageRoute(builder: (_) => Text('route ${s.name}')),
        ),
      ),
    );
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('skipSetup')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('skipConfirm')));
    await t.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(UserPrefsService.onboardingCompletedKey), isNull);

    await t.enterText(find.byKey(const Key('skipName')), '  Abhranil ');
    await t.tap(find.byKey(const Key('skipConfirm')));
    await t.pumpAndSettle();
    expect(await UserPrefsService.getUserName(), 'Abhranil');
    expect(prefs.getBool(UserPrefsService.onboardingCompletedKey), isTrue);
  });
}
