// Beta.3: predictive back on custom-style routes and on the shell tabs/Home.
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/routes/predictive_back.dart';
import 'package:expensetracker_reloaded/screens/main_shell.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _send(WidgetTester t, String method, [double p = 0]) async {
  final msg = const StandardMethodCodec().encodeMethodCall(
    MethodCall(
      method,
      method.endsWith('Gesture') && method != 'startBackGesture'
          ? null
          : {
              'touchOffset': [5.0, 300.0],
              'progress': p,
              'swipeEdge': 0,
            },
    ),
  );
  await t.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    msg,
    (_) {},
  );
  await t.pump();
}

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
  setUp(() {
    SharedPreferences.setMockInitialValues({'userName': 'Abhranil'});
    AppSettings.animations = true;
  });

  test('custom styles map to a matching back motion', () {
    expect(backStyleFor(AnimationType.slideLeft), BackStyle.slideToLeft);
    expect(backStyleFor(AnimationType.slideRight), BackStyle.slideToRight);
    expect(backStyleFor(AnimationType.fadeSlide), BackStyle.shrink);
  });

  for (final type in [AnimationType.slideRight, AnimationType.fadeSlide]) {
    testWidgets('swipe on a ${type.name} page tracks the finger', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AnimationVariants.setAnimationType(type);
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(navigatorKey: nav, home: const Text('home')),
      );
      nav.currentState!.push(AnimationVariants.createRoute(const Text('page')));
      await t.pumpAndSettle();
      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.5);
      expect(find.text('home'), findsOneWidget); // peeking behind
      final m = t
          .widgetList<Transform>(
            find.ancestor(
              of: find.text('page'),
              matching: find.byType(Transform),
            ),
          )
          .map((w) => w.transform)
          .toList();
      expect(m.any((x) => !x.isIdentity()), isTrue);
      await _send(t, 'cancelBackGesture');
      await t.pumpAndSettle();
      expect(find.text('page'), findsOneWidget); // cancel keeps the page
      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.9);
      await _send(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('page'), findsNothing);
      AnimationVariants.setAnimationType(AnimationType.fadeSlide);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('tab swipe peeks Home; cancel stays, commit lands Home', (
    t,
  ) async {
    final c = ProviderContainer(
      overrides: [
        reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    await t.pumpWidget(_shell(c));
    await t.tap(find.text('Settings'));
    await t.pump();
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.4);
    expect(find.text('home-body'), findsOneWidget);
    expect(find.text('settings-body'), findsOneWidget);
    await _send(t, 'cancelBackGesture');
    await t.pumpAndSettle();
    expect(c.read(shellTabProvider), 3);
    expect(find.text('home-body'), findsNothing);

    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.8);
    await _send(t, 'commitBackGesture');
    await t.pumpAndSettle();
    expect(c.read(shellTabProvider), MainShell.homeIndex);
    expect(find.text('settings-body'), findsNothing);
    expect(find.text('Leaving already?'), findsNothing);
  });

  testWidgets('Home swipe commit asks before leaving', (t) async {
    final c = ProviderContainer(
      overrides: [
        reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    await t.pumpWidget(_shell(c));
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.7);
    await _send(t, 'commitBackGesture');
    await t.pumpAndSettle();
    expect(find.text('Leaving already?'), findsOneWidget);
    await t.tap(find.byKey(const Key('leave-stay')));
    await t.pumpAndSettle();
    expect(find.text('home-body'), findsOneWidget);
  });

  testWidgets('animations off: tab Back still goes Home, no peek', (t) async {
    AppSettings.animations = false;
    final c = ProviderContainer(
      overrides: [
        reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    await t.pumpWidget(_shell(c));
    await t.tap(find.text('Settings'));
    await t.pump();
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.5);
    expect(find.text('home-body'), findsNothing); // no peek
    await _send(t, 'commitBackGesture');
    await t.pumpAndSettle();
    expect(c.read(shellTabProvider), MainShell.homeIndex);
    AppSettings.animations = true;
  });
}
