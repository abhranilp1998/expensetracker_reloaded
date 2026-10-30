// Predictive back plays the user's selected animation style in reverse,
// following the finger: pushed pages, tabs -> Home, and the Home peek.
import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/screens/main_shell.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _send(WidgetTester t, String method, [double p = 0]) async {
  final hasArgs =
      method == 'startBackGesture' || method == 'updateBackGestureProgress';
  final msg = const StandardMethodCodec().encodeMethodCall(
    MethodCall(
      method,
      hasArgs
          ? {
              'touchOffset': [5.0, 300.0],
              'progress': p,
              'swipeEdge': 0,
            }
          : null,
    ),
  );
  await t.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    msg,
    (_) {},
  );
  await t.pump();
}

/// What the style's transition widgets around [text] currently show.
class _Look {
  _Look(WidgetTester t, String text) {
    final above = find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((_) => true),
    );
    for (final w in t.widgetList(above)) {
      if (w is FadeTransition) opacity *= w.opacity.value;
      if (w is SlideTransition) offset += w.position.value;
      if (w is ScaleTransition) scale *= w.scale.value;
      if (w is RotationTransition) turns += w.turns.value;
    }
  }
  double opacity = 1, scale = 1, turns = 0;
  Offset offset = Offset.zero;
  bool get atRest =>
      (opacity - 1).abs() < 1e-3 &&
      (scale - 1).abs() < 1e-3 &&
      turns.abs() < 1e-3 &&
      offset.distance < 1e-3;
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

ProviderContainer _container() => ProviderContainer(
  overrides: [
    reviewQueueProvider.overrideWith((ref) => Stream.value(const [])),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'userName': 'Abhranil'});
    AppSettings.animations = true;
  });
  tearDown(() {
    AnimationVariants.setAnimationType(AnimationType.fadeSlide);
    AppSettings.animations = true;
  });

  for (final type in AnimationType.values) {
    testWidgets('${type.name}: back swipe plays this style in reverse', (
      t,
    ) async {
      AnimationVariants.setAnimationType(type);
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Text('home'),
        ),
      );
      final route =
          AnimationVariants.createRoute(const Text('page')) as PageRouteBuilder;
      nav.currentState!.push(route);
      await t.pumpAndSettle();
      expect(_Look(t, 'page').atRest, isTrue);

      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.5);
      // Finger progress 0.5 -> route animation 0.5, and the page is drawn by
      // this style's own transitionsBuilder at that value.
      expect(route.animation!.value, closeTo(0.5, 1e-6));
      final mid = _Look(t, 'page');
      expect(mid.atRest, isFalse, reason: 'style must move under the finger');
      expect(find.text('home'), findsOneWidget);
      if (type == AnimationType.slideLeft) expect(mid.offset.dx, lessThan(0));
      if (type == AnimationType.slideRight) {
        expect(mid.offset.dx, greaterThan(0));
      }

      await _send(t, 'cancelBackGesture');
      await t.pumpAndSettle();
      expect(_Look(t, 'page').atRest, isTrue); // cancel = style's rest state

      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.8);
      await _send(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('page'), findsNothing); // commit = style's exit
    });
  }

  testWidgets('animations off: no transition widgets, instant pop', (t) async {
    AppSettings.animations = false;
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Text('home'),
      ),
    );
    nav.currentState!.push(AnimationVariants.createRoute(const Text('page')));
    await t.pumpAndSettle();
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.5);
    expect(_Look(t, 'page').atRest, isTrue);
    await _send(t, 'commitBackGesture');
    await t.pump();
    await t.pump();
    expect(find.text('page'), findsNothing);
  });

  for (final type in [AnimationType.slideRight, AnimationType.scaleRotate]) {
    testWidgets('${type.name}: tab swipe uses the style; cancel/commit', (
      t,
    ) async {
      AnimationVariants.setAnimationType(type);
      final c = _container();
      addTearDown(c.dispose);
      await t.pumpWidget(_shell(c));
      await t.tap(find.text('Settings'));
      await t.pump();
      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.4);
      expect(find.text('home-body'), findsOneWidget); // Home behind
      expect(_Look(t, 'settings-body').atRest, isFalse);
      await _send(t, 'cancelBackGesture');
      await t.pumpAndSettle();
      expect(c.read(shellTabProvider), 3);
      expect(_Look(t, 'settings-body').atRest, isTrue);
      expect(find.text('home-body'), findsNothing);

      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.8);
      await _send(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(c.read(shellTabProvider), MainShell.homeIndex);
      expect(find.text('settings-body'), findsNothing);
      expect(find.text('Leaving already?'), findsNothing);
    });
  }

  testWidgets('Home swipe peeks with the style, commit asks', (t) async {
    AnimationVariants.setAnimationType(AnimationType.slideLeft);
    final c = _container();
    addTearDown(c.dispose);
    await t.pumpWidget(_shell(c));
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.6);
    expect(_Look(t, 'home-body').offset.dx, lessThan(0));
    await _send(t, 'commitBackGesture');
    await t.pumpAndSettle();
    expect(find.text('Leaving already?'), findsOneWidget);
    expect(_Look(t, 'home-body').atRest, isTrue);
    await t.tap(find.byKey(const Key('leave-stay')));
    await t.pumpAndSettle();
    expect(find.text('home-body'), findsOneWidget);
  });

  testWidgets('animations off: tab Back still goes Home, no peek', (t) async {
    AppSettings.animations = false;
    final c = _container();
    addTearDown(c.dispose);
    await t.pumpWidget(_shell(c));
    await t.tap(find.text('Settings'));
    await t.pump();
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.5);
    expect(find.text('home-body'), findsNothing);
    await _send(t, 'commitBackGesture');
    await t.pumpAndSettle();
    expect(c.read(shellTabProvider), MainShell.homeIndex);
  });
}
