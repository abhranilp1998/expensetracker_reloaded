// Every animation style is distinct, follows the predictive back finger in
// reverse (linear while the finger drives it), cancels back to rest and
// commits to its exit. Also tabs -> Home and the Home peek.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:expensetracker_reloaded/providers/providers.dart';
import 'package:expensetracker_reloaded/routes/animation_preferences.dart';
import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/screens/main_shell.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';
import 'package:expensetracker_reloaded/widgets/animation_style_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

final _shot = GlobalKey();

/// Pixels of the whole app (small, so it is quick).
Future<Uint8List> _pixels(WidgetTester t) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await t.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 0.25);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 8) diff++;
  }
  return diff < a.length * 0.002;
}

/// A page with structure so every transform/clip changes pixels.
Widget _page() => Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF6A1B9A), Color(0xFF00897B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: GridView.count(
    crossAxisCount: 4,
    children: [
      for (var i = 0; i < 24; i++)
        Container(
          margin: const EdgeInsets.all(6),
          color: i.isEven ? Colors.amber : Colors.white,
        ),
    ],
  ),
);

Widget _app(GlobalKey<NavigatorState> nav) => RepaintBoundary(
  key: _shot,
  child: MaterialApp(
    navigatorKey: nav,
    theme: ThemeData(platform: TargetPlatform.android),
    home: const ColoredBox(color: Colors.black, child: SizedBox.expand()),
  ),
);

Widget _shell(ProviderContainer c) => UncontrolledProviderScope(
  container: c,
  child: RepaintBoundary(
    key: _shot,
    child: MaterialApp(
      home: MainShell(
        pagesOverride: [
          const Center(child: Text('home-body')),
          const Center(child: Text('activity-body')),
          const Center(child: Text('review-body')),
          Stack(
            children: [
              _page(),
              const Center(child: Text('settings-body')),
            ],
          ),
        ],
      ),
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

  test('catalogue: 16 styles, unique names, every style described', () {
    expect(AnimationType.values.length, 16);
    expect(motionStyles.keys.toSet(), AnimationType.values.toSet());
    final names = motionStyles.values.map((s) => s.name).toSet();
    expect(names.length, 16);
  });

  final midShots = <AnimationType, Uint8List>{};

  for (final type in AnimationType.values) {
    testWidgets('${type.name}: swipe plays it in reverse, cancel, commit', (
      t,
    ) async {
      AnimationVariants.setAnimationType(type);
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(_app(nav));
      final route = AnimationVariants.createRoute(_page()) as LedgerlyPageRoute;
      expect(route.motion, type);
      nav.currentState!.push(route);
      await t.pumpAndSettle();
      final rest = await _pixels(t);

      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.5);
      expect(route.animation!.value, closeTo(0.5, 1e-6));
      final mid = await _pixels(t);
      expect(_same(mid, rest), isFalse, reason: 'style must move');
      midShots[type] = mid;
      // Small finger moves change the picture smoothly (no overshoot jumps).
      await _send(t, 'updateBackGestureProgress', 0.52);
      expect(t.takeException(), isNull);

      await _send(t, 'cancelBackGesture');
      await t.pumpAndSettle();
      expect(_same(await _pixels(t), rest), isTrue, reason: 'cancel = rest');

      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.8);
      await _send(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(nav.currentState!.canPop(), isFalse, reason: 'commit = exit');
      expect(t.takeException(), isNull);
    });
  }

  test('all 16 styles look different half way through', () {
    final list = midShots.entries.toList();
    expect(list.length, AnimationType.values.length);
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        expect(
          _same(list[i].value, list[j].value),
          isFalse,
          reason: '${list[i].key.name} vs ${list[j].key.name}',
        );
      }
    }
  });

  testWidgets('Back button (no swipe) runs each exit without errors', (
    t,
  ) async {
    for (final type in AnimationType.values) {
      AnimationVariants.setAnimationType(type);
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(_app(nav));
      nav.currentState!.push(AnimationVariants.createRoute(_page()));
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(nav.currentState!.canPop(), isFalse, reason: type.name);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('animations off: no motion, instant pop', (t) async {
    AppSettings.animations = false;
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(_app(nav));
    nav.currentState!.push(AnimationVariants.createRoute(_page()));
    await t.pumpAndSettle();
    final rest = await _pixels(t);
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.5);
    expect(_same(await _pixels(t), rest), isTrue);
    await _send(t, 'commitBackGesture');
    await t.pump();
    await t.pump();
    expect(nav.currentState!.canPop(), isFalse);
  });

  for (final type in [
    AnimationType.slideRight,
    AnimationType.kaleidoscope,
    AnimationType.elasticBounce,
  ]) {
    testWidgets('${type.name}: tab swipe uses the style; cancel/commit', (
      t,
    ) async {
      AnimationVariants.setAnimationType(type);
      final c = _container();
      addTearDown(c.dispose);
      await t.pumpWidget(_shell(c));
      await t.tap(find.text('Settings'));
      await t.pumpAndSettle();
      final rest = await _pixels(t);
      await _send(t, 'startBackGesture', 0);
      await _send(t, 'updateBackGestureProgress', 0.4);
      expect(find.text('home-body'), findsOneWidget); // Home behind
      expect(_same(await _pixels(t), rest), isFalse);
      await _send(t, 'cancelBackGesture');
      await t.pumpAndSettle();
      expect(c.read(shellTabProvider), 3);
      expect(_same(await _pixels(t), rest), isTrue);
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
    final rest = await _pixels(t);
    await _send(t, 'startBackGesture', 0);
    await _send(t, 'updateBackGestureProgress', 0.6);
    expect(_same(await _pixels(t), rest), isFalse);
    await _send(t, 'commitBackGesture');
    await t.pumpAndSettle();
    expect(find.text('Leaving already?'), findsOneWidget);
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

  test(
    'saved styles from older versions still load (Kaleidoscope kept)',
    () async {
      for (final old in [
        'fadeSlide',
        'slideLeft',
        'slideRight',
        'scaleRotate',
        'morphing',
        'bouncy',
        'liquid',
        'staggered',
        'kaleidoscope',
        'elasticBounce',
      ]) {
        SharedPreferences.setMockInitialValues({
          'animationType': 'AnimationType.$old',
        });
        final t = await AnimationPreferencesService.loadAnimationType();
        expect(t.name, old);
      }
    },
  );

  testWidgets('style picker: collapsed, expands grouped, selects, collapses', (
    t,
  ) async {
    var value = AnimationType.kaleidoscope;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => AnimationStylePicker(
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Kaleidoscope'), findsOneWidget);
    expect(find.byKey(const Key('anim-picker-list')), findsNothing);

    await t.tap(find.byKey(const Key('anim-picker-header')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('anim-picker-list')), findsOneWidget);
    for (final g in ['Slides', 'Zooms', 'Reveals', 'Springs']) {
      expect(find.text(g), findsOneWidget);
    }
    await t.ensureVisible(find.byKey(const Key('anim-style-pageFlip')));
    await t.tap(find.byKey(const Key('anim-style-pageFlip')));
    await t.pumpAndSettle();
    expect(value, AnimationType.pageFlip);

    await t.ensureVisible(find.byKey(const Key('anim-picker-header')));
    await t.tap(find.byKey(const Key('anim-picker-header')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('anim-picker-list')), findsNothing);
    expect(find.text('Page Flip'), findsOneWidget);
  });
}
