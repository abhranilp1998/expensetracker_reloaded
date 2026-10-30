// Renders every animation style to PNG frames for visual review.
// Skipped unless RENDER_EVIDENCE=<output dir> is set, e.g.
//   RENDER_EVIDENCE=/tmp/frames flutter test test/tool/render_motion_evidence_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _shot = GlobalKey();

Widget _page(Color a, Color b, String label) => Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [a, b],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(height: 60, color: Colors.white24, alignment: Alignment.center),
      const SizedBox(height: 16),
      for (var i = 0; i < 6; i++)
        Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: i.isEven ? Colors.white : Colors.amber,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
    ],
  ),
);

Future<void> _save(WidgetTester t, String path) async {
  final b = _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await b.toImage(pixelRatio: 0.6);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    File(path).writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _back(WidgetTester t, String m, [double p = 0]) async {
  final args = m == 'startBackGesture' || m == 'updateBackGestureProgress'
      ? {
          'touchOffset': [5.0, 300.0],
          'progress': p,
          'swipeEdge': 0,
        }
      : null;
  await t.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(MethodCall(m, args)),
    (_) {},
  );
  await t.pump();
}

void main() {
  final out = Platform.environment['RENDER_EVIDENCE'];
  for (final type in AnimationType.values) {
    testWidgets('render ${type.name}', (t) async {
      t.view.physicalSize = const Size(412, 892);
      t.view.devicePixelRatio = 1;
      AppSettings.animations = true;
      AnimationVariants.setAnimationType(type);
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        RepaintBoundary(
          key: _shot,
          child: MaterialApp(
            navigatorKey: nav,
            theme: ThemeData(platform: TargetPlatform.android),
            home: _page(
              const Color(0xFF263238),
              const Color(0xFF455A64),
              'home',
            ),
          ),
        ),
      );
      final dir = Directory('$out/${type.name}')..createSync(recursive: true);
      nav.currentState!.push(
        AnimationVariants.createRoute(
          _page(const Color(0xFF6A1B9A), const Color(0xFF00897B), 'detail'),
        ),
      );
      await t.pump();
      final total = motionStyles[type]!.duration;
      const n = 12;
      for (var i = 0; i <= n; i++) {
        await _save(t, '${dir.path}/open_${i.toString().padLeft(2, '0')}.png');
        await t.pump(total ~/ n);
      }
      await t.pumpAndSettle();
      // Predictive back: finger drives it, frames at increasing progress.
      await _back(t, 'startBackGesture', 0);
      for (var i = 1; i <= 6; i++) {
        await _back(t, 'updateBackGestureProgress', i / 7);
        await _save(t, '${dir.path}/back_$i.png');
      }
      await _back(t, 'commitBackGesture');
      await t.pumpAndSettle();
      AnimationVariants.setAnimationType(AnimationType.fadeSlide);
      t.view.reset();
    }, skip: out == null);
  }
}
