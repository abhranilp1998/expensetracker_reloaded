// Ledgerly page motions: one function per style, all driven by a single
// progress value so every style can run forward (open), backward (pop) and
// live under the finger (Android predictive back).
//
// Conventions:
// * t = raw animation value, 1 = page fully shown, 0 = page gone.
// * During a back gesture (and its settle) motion is LINEAR in t, so springs
//   and overshoots never jitter while the finger drives them backwards.
// * Otherwise the style's curve is applied. Overshoot ("spring") curves are
//   only used for movement/scale, and only when opening; fades never bounce
//   (M3 Expressive: spatial springs may overshoot, effects springs may not).
// * Every style keeps the same widget tree shape at every t (no state loss).
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:expensetracker_reloaded/routes/animation_variants.dart'
    show AnimationType;

/// Settings groups.
enum MotionGroup {
  slides('Slides'),
  zooms('Zooms'),
  reveals('Reveals'),
  springs('Springs');

  const MotionGroup(this.label);
  final String label;
}

/// Display data + timing for one style.
class MotionStyle {
  const MotionStyle({
    required this.name,
    required this.description,
    required this.icon,
    required this.emoji,
    required this.duration,
    required this.group,
    this.curve = Curves.easeInOutCubicEmphasized,
    this.springy = false,
  });

  final String name;
  final String description;
  final IconData icon;
  final String emoji;
  final Duration duration;
  final MotionGroup group;

  /// Opening curve for movement.
  final Curve curve;

  /// True when [curve] overshoots (only used when opening).
  final bool springy;
}

/// The catalogue, in the order shown in Settings.
const Map<AnimationType, MotionStyle> motionStyles = {
  AnimationType.fadeSlide: MotionStyle(
    group: MotionGroup.slides,
    name: 'Fade Up',
    description: 'Fades in while rising a little from below',
    icon: Icons.vertical_align_top,
    emoji: '🌅',
    duration: Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  ),
  AnimationType.slideLeft: MotionStyle(
    group: MotionGroup.slides,
    name: 'Slide Left',
    description: 'Full page slides in from the left edge',
    icon: Icons.arrow_forward,
    emoji: '⬅️',
    duration: Duration(milliseconds: 380),
  ),
  AnimationType.slideRight: MotionStyle(
    group: MotionGroup.slides,
    name: 'Slide Right',
    description: 'Full page slides in from the right edge',
    icon: Icons.arrow_back,
    emoji: '➡️',
    duration: Duration(milliseconds: 380),
  ),
  AnimationType.cardStack: MotionStyle(
    group: MotionGroup.slides,
    name: 'Card Stack',
    description: 'iOS-style push: card with shadow, page behind parallaxes',
    icon: Icons.layers,
    emoji: '🃏',
    duration: Duration(milliseconds: 420),
    curve: Curves.fastEaseInToSlowEaseOut,
  ),
  AnimationType.sharedAxis: MotionStyle(
    group: MotionGroup.slides,
    name: 'Shared Axis',
    description: 'Material fade-through with a short sideways shift',
    icon: Icons.swap_horiz,
    emoji: '↔️',
    duration: Duration(milliseconds: 320),
  ),
  AnimationType.scaleRotate: MotionStyle(
    group: MotionGroup.zooms,
    name: 'Scale + Rotate',
    description: 'Grows in while untwisting from a slight tilt',
    icon: Icons.rotate_right,
    emoji: '🔄',
    duration: Duration(milliseconds: 440),
    curve: Curves.easeOutCubic,
  ),
  AnimationType.bouncy: MotionStyle(
    group: MotionGroup.springs,
    name: 'Bouncy Pop',
    description: 'Pops up from small with a springy overshoot',
    icon: Icons.sports_basketball,
    emoji: '🏀',
    duration: Duration(milliseconds: 520),
    curve: Curves.easeOutBack,
    springy: true,
  ),
  AnimationType.elasticBounce: MotionStyle(
    group: MotionGroup.springs,
    name: 'Elastic Drop',
    description: 'Drops from the top and settles with an elastic wobble',
    icon: Icons.south,
    emoji: '🎾',
    duration: Duration(milliseconds: 750),
    curve: ElasticOutCurve(0.55),
    springy: true,
  ),
  AnimationType.zoomExpand: MotionStyle(
    group: MotionGroup.zooms,
    name: 'Zoom Expand',
    description: 'Grows out of a rounded card like a container transform',
    icon: Icons.open_in_full,
    emoji: '🔍',
    duration: Duration(milliseconds: 460),
  ),
  AnimationType.circleReveal: MotionStyle(
    group: MotionGroup.reveals,
    name: 'Circle Reveal',
    description: 'Circular reveal spreading from the bottom-right corner',
    icon: Icons.radio_button_unchecked,
    emoji: '⭕',
    duration: Duration(milliseconds: 480),
    curve: Curves.easeInOutCubic,
  ),
  AnimationType.morphing: MotionStyle(
    group: MotionGroup.reveals,
    name: 'Blob Reveal',
    description: 'Wobbly blob grows from the centre to fill the screen',
    icon: Icons.bubble_chart,
    emoji: '🫧',
    duration: Duration(milliseconds: 560),
    curve: Curves.easeInOutCubic,
  ),
  AnimationType.liquid: MotionStyle(
    group: MotionGroup.reveals,
    name: 'Liquid Swipe',
    description: 'A wavy liquid edge sweeps across from the right',
    icon: Icons.water,
    emoji: '💧',
    duration: Duration(milliseconds: 620),
    curve: Curves.easeInOutCubic,
  ),
  AnimationType.staggered: MotionStyle(
    group: MotionGroup.reveals,
    name: 'Cascade Blinds',
    description: 'Page reveals in horizontal strips, one after another',
    icon: Icons.view_day,
    emoji: '📚',
    duration: Duration(milliseconds: 560),
    curve: Curves.linear,
  ),
  AnimationType.kaleidoscope: MotionStyle(
    group: MotionGroup.reveals,
    name: 'Kaleidoscope',
    description: 'Twelve rotating wedges open up like a kaleidoscope',
    icon: Icons.filter_vintage,
    emoji: '🎪',
    duration: Duration(milliseconds: 620),
    curve: Curves.easeInOutCubic,
  ),
  AnimationType.glassBlur: MotionStyle(
    group: MotionGroup.zooms,
    name: 'Glass Blur',
    description: 'Comes into focus from a frosted-glass blur',
    icon: Icons.blur_on,
    emoji: '🧊',
    duration: Duration(milliseconds: 400),
    curve: Curves.easeOutCubic,
  ),
  AnimationType.pageFlip: MotionStyle(
    group: MotionGroup.slides,
    name: 'Page Flip',
    description: 'Swings in like a page turning on its left edge',
    icon: Icons.menu_book,
    emoji: '📖',
    duration: Duration(milliseconds: 520),
    curve: Curves.easeOutCubic,
  ),
};

double _interval(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

/// Builds [child] as it looks at [animation] for [type].
///
/// [secondary] is the animation of a page pushed ON TOP of this one (used by
/// Card Stack and Shared Axis to move the page behind). [gesture] = true while
/// a back swipe drives the value (linear mapping, no overshoot).
Widget buildMotion(
  AnimationType type,
  Animation<double> animation,
  Animation<double> secondary,
  Widget child, {
  required bool Function() gesture,
}) {
  final style = motionStyles[type]!;
  return AnimatedBuilder(
    animation: Listenable.merge([animation, secondary]),
    child: child,
    builder: (context, child) {
      final t = animation.value.clamp(0.0, 1.0);
      final linear = gesture();
      final reversing = animation.status == AnimationStatus.reverse;
      // e: movement progress; may overshoot >1 only for springy opening.
      final double e;
      if (linear) {
        e = t;
      } else if (style.springy && reversing) {
        e = Curves.easeInCubic.flipped.transform(t);
      } else {
        e = style.curve.transform(t);
      }
      final f = Curves.easeOut.transform(t); // fades: never overshoot
      final s = secondary.value.clamp(0.0, 1.0);
      final size = MediaQuery.sizeOf(context);
      return _paint(type, e, f, t, s, size, child!);
    },
  );
}

Widget _paint(
  AnimationType type,
  double e,
  double f,
  double t,
  double s,
  Size size,
  Widget child,
) {
  final w = size.width, h = size.height;
  switch (type) {
    case AnimationType.fadeSlide:
      return Opacity(
        opacity: f,
        child: Transform.translate(
          offset: Offset(0, (1 - e) * h * 0.08),
          child: child,
        ),
      );
    case AnimationType.slideLeft:
      return Transform.translate(offset: Offset(-(1 - e) * w, 0), child: child);
    case AnimationType.slideRight:
      return Transform.translate(offset: Offset((1 - e) * w, 0), child: child);
    case AnimationType.cardStack:
      // iOS-style card: a scrim darkens the page behind while the card (with
      // a shadow and rounded leading corners) slides in from the right. When
      // this page is covered (s) it drifts left a third and dims.
      final shown = e.clamp(0.0, 1.0);
      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.3 * shown),
            ),
          ),
          Transform.translate(
            offset: Offset((1 - e) * w - s * w * 0.3, 0),
            child: Transform.scale(
              // The card is lifted (slightly smaller) while it travels.
              scale: 0.9 + 0.1 * shown,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25 * s),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.4 * (1 - shown),
                        ),
                        blurRadius: 28,
                        offset: const Offset(-8, 0),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(24 * (1 - shown)),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    case AnimationType.sharedAxis:
      // Fade-through: in = fades in after 30%, from +30dp; covered = fades
      // out in the first 30% while moving -30dp.
      final inOp = _interval(t, 0.3, 1.0);
      final outOp = 1 - _interval(s, 0.0, 0.3);
      return Opacity(
        opacity: inOp * outOp,
        child: Transform.translate(
          offset: Offset((1 - e) * 30 - s * 30, 0),
          child: child,
        ),
      );
    case AnimationType.scaleRotate:
      return Opacity(
        opacity: f,
        child: Transform.rotate(
          angle: (1 - e) * -0.14,
          child: Transform.scale(scale: 0.78 + 0.22 * e, child: child),
        ),
      );
    case AnimationType.bouncy:
      return Opacity(
        opacity: _interval(t, 0.0, 0.5),
        child: Transform.scale(scale: 0.55 + 0.45 * e, child: child),
      );
    case AnimationType.elasticBounce:
      return Transform.translate(offset: Offset(0, -(1 - e) * h), child: child);
    case AnimationType.zoomExpand:
      final from = Rect.fromLTWH(w * 0.08, h * 0.30, w * 0.84, h * 0.22);
      final rect = Rect.lerp(from, Offset.zero & size, e)!;
      return Opacity(
        opacity: _interval(t, 0.0, 0.25),
        child: ClipPath(clipper: _RRectClip(rect, 28 * (1 - e)), child: child),
      );
    case AnimationType.circleReveal:
      final c = Offset(w * 0.86, h * 0.88);
      final r = e * math.sqrt(w * w + h * h);
      return ClipPath(clipper: _CircleClip(c, r), child: child);
    case AnimationType.morphing:
      return ClipPath(clipper: _BlobClip(e, t), child: child);
    case AnimationType.liquid:
      return ClipPath(clipper: _LiquidClip(e), child: child);
    case AnimationType.staggered:
      return ClipPath(clipper: _BlindsClip(t), child: child);
    case AnimationType.kaleidoscope:
      return ClipPath(
        clipper: _WedgeClip(e),
        child: Transform.rotate(
          angle: (1 - e) * 0.6,
          child: Transform.scale(scale: 0.85 + 0.15 * e, child: child),
        ),
      );
    case AnimationType.glassBlur:
      final sigma = (1 - f) * 16;
      return Opacity(
        opacity: f,
        child: ImageFiltered(
          enabled: sigma > 0.01,
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Transform.scale(scale: 1.06 - 0.06 * e, child: child),
        ),
      );
    case AnimationType.pageFlip:
      final m = Matrix4.identity()
        ..setEntry(3, 2, 0.0011)
        ..rotateY((1 - e) * math.pi / 2);
      return Transform(
        alignment: Alignment.centerLeft,
        transform: m,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35 * (1 - e).clamp(0, 1)),
          ),
          child: child,
        ),
      );
  }
}

// ---- Clippers ---------------------------------------------------------------

class _RRectClip extends CustomClipper<Path> {
  _RRectClip(this.rect, this.radius);
  final Rect rect;
  final double radius;
  @override
  Path getClip(Size size) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  @override
  bool shouldReclip(_RRectClip old) => old.rect != rect || old.radius != radius;
}

class _CircleClip extends CustomClipper<Path> {
  _CircleClip(this.c, this.r);
  final Offset c;
  final double r;
  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: c, radius: r));
  @override
  bool shouldReclip(_CircleClip old) => old.r != r || old.c != c;
}

/// Organic blob: radius wobbles with angle; wobble fades out as it fills.
class _BlobClip extends CustomClipper<Path> {
  _BlobClip(this.e, this.t);
  final double e, t;
  @override
  Path getClip(Size size) {
    final c = size.center(Offset.zero);
    final full =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final base = e * full * 1.15;
    final wob = 0.16 * (1 - t);
    final path = Path();
    const n = 72;
    for (var i = 0; i <= n; i++) {
      final a = i / n * 2 * math.pi;
      final r =
          base *
          (1 +
              wob * math.sin(3 * a + t * 5) +
              wob * 0.6 * math.cos(5 * a - t * 3));
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_BlobClip old) => old.e != e || old.t != t;
}

/// Region right of a wavy vertical edge that sweeps right -> left, with a
/// liquid bulge at 60% height.
class _LiquidClip extends CustomClipper<Path> {
  _LiquidClip(this.e);
  final double e;
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final edge = w * (1 - e);
    final bulge = w * 0.35 * math.sin(math.pi * e.clamp(0.0, 1.0));
    final cy = h * 0.6;
    final path = Path()
      ..moveTo(w, 0)
      ..lineTo(edge, 0);
    const n = 48;
    for (var i = 0; i <= n; i++) {
      final y = h * i / n;
      final d = (y - cy) / (h * 0.28);
      final x =
          edge - bulge * math.exp(-d * d) + 6 * (1 - e) * math.sin(y / 40);
      path.lineTo(x, y);
    }
    return path
      ..lineTo(w, h)
      ..close();
  }

  @override
  bool shouldReclip(_LiquidClip old) => old.e != e;
}

/// Seven horizontal blinds, each opening downward slightly after the one
/// above it.
class _BlindsClip extends CustomClipper<Path> {
  _BlindsClip(this.t);
  final double t;
  static const bands = 7;
  @override
  Path getClip(Size size) {
    final bh = size.height / bands;
    final path = Path();
    for (var i = 0; i < bands; i++) {
      final start = i * 0.07;
      final p = Curves.easeOutCubic.transform(
        _interval(t, start, start + 1 - (bands - 1) * 0.07),
      );
      path.addRect(Rect.fromLTWH(0, i * bh, size.width, bh * p + 0.5 * p));
    }
    return path;
  }

  @override
  bool shouldReclip(_BlindsClip old) => old.t != t;
}

/// Twelve wedges around the centre widening until they meet.
class _WedgeClip extends CustomClipper<Path> {
  _WedgeClip(this.e);
  final double e;
  static const n = 12;
  @override
  Path getClip(Size size) {
    final c = size.center(Offset.zero);
    final r = math.sqrt(size.width * size.width + size.height * size.height);
    final seg = 2 * math.pi / n;
    final span = seg * e.clamp(0.0, 1.0);
    final spin = (1 - e) * math.pi / 3;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final a = i * seg + spin;
      path
        ..moveTo(c.dx, c.dy)
        ..arcTo(Rect.fromCircle(center: c, radius: r), a, span + 0.002, false)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(_WedgeClip old) => old.e != e;
}
