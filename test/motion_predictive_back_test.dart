import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';
import 'package:expensetracker_reloaded/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every route variant is a predictive-back aware LedgerlyPageRoute', () {
    AppSettings.animations = true;
    for (final type in AnimationType.values) {
      AnimationVariants.setAnimationType(type);
      expect(
        AnimationVariants.createRoute(const SizedBox()),
        isA<LedgerlyPageRoute>(),
        reason: type.name,
      );
    }
    AnimationVariants.setAnimationType(AnimationType.fadeSlide);
  });

  test('themes use PredictiveBackPageTransitionsBuilder on Android', () {
    for (final t in [
      AppThemeData.lightTheme(Colors.blue),
      AppThemeData.darkTheme(Colors.blue),
    ]) {
      expect(
        t.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<PredictiveBackPageTransitionsBuilder>(),
      );
    }
  });

  testWidgets('back on a pushed page pops cleanly to the page behind', (
    tester,
  ) async {
    AppSettings.animations = true;
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        theme: AppThemeData.lightTheme(Colors.blue),
        home: const Text('home'),
      ),
    );
    key.currentState!.push(AnimationVariants.createRoute(const Text('page')));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
