import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:expensetracker_reloaded/services/app_settings.dart';

/// How a page follows an Android predictive-back swipe (Android 14+).
///
/// Each of the user's route animation styles maps to the back motion that
/// matches how the page came in, so the swipe "undoes" the opening:
/// * [slideToLeft] / [slideToRight]: the page slides off with the finger.
/// * [shrink]: Material predictive look (scale down, nudge, round corners)
///   for fade/scale/vertical styles, which have no horizontal direction.
enum BackStyle { shrink, slideToLeft, slideToRight }

/// True when motion should be skipped (phone reduce-motion or the
/// Settings > Enable Animations switch is off).
bool reduceMotion(BuildContext context) =>
    !AppSettings.animations ||
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// Paints [child] at back-swipe [progress] (0 = untouched, 1 = gone).
///
/// [fadeOut] is only used after the swipe is committed (or on a plain Back
/// press), so a half pull never makes the page see-through.
Widget predictiveBackTransform({
  required BuildContext context,
  required BackStyle style,
  required double progress,
  required SwipeEdge edge,
  required Widget child,
  double fadeOut = 0,
}) {
  final p = progress.clamp(0.0, 1.0);
  final width = MediaQuery.sizeOf(context).width;
  final towardRight = edge == SwipeEdge.left;
  Widget out;
  switch (style) {
    case BackStyle.slideToLeft:
    case BackStyle.slideToRight:
      final dir = style == BackStyle.slideToRight ? 1.0 : -1.0;
      out = Transform.translate(
        offset: Offset(dir * p * width, 0),
        child: child,
      );
    case BackStyle.shrink:
      // Matches Material's predictive page: up to 10% smaller, shifted ~8%
      // toward the swipe, corners rounding in.
      final scale = 1 - 0.1 * p;
      final dx = (towardRight ? 1 : -1) * p * width * 0.08;
      out = Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.scale(
          scale: scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(math.min(28, 40 * p)),
            child: child,
          ),
        ),
      );
  }
  // Always present so the widget tree keeps the same shape (no state loss).
  return Opacity(opacity: (1 - fadeOut).clamp(0.0, 1.0), child: out);
}

/// Receives the system back-gesture events for one route and drives the
/// route's own animation from the finger (start / progress / cancel /
/// commit). Must stay mounted for the route's whole life, otherwise the
/// gesture start is missed (the beta.1 bug).
class RouteBackGestureListener extends StatefulWidget {
  const RouteBackGestureListener({
    super.key,
    required this.route,
    required this.builder,
  });

  final ModalRoute<dynamic> route;

  /// [edge] is null when no swipe is in progress.
  final Widget Function(BuildContext context, SwipeEdge? edge) builder;

  @override
  State<RouteBackGestureListener> createState() =>
      _RouteBackGestureListenerState();
}

class _RouteBackGestureListenerState extends State<RouteBackGestureListener>
    with WidgetsBindingObserver {
  SwipeEdge? _edge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final r = widget.route;
    if (!r.isCurrent || !r.popGestureEnabled) return false;
    r.handleStartBackGesture(progress: 1 - backEvent.progress);
    setState(() => _edge = backEvent.swipeEdge);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
  }

  @override
  void handleCancelBackGesture() {
    widget.route.handleCancelBackGesture();
    setState(() => _edge = null);
  }

  @override
  void handleCommitBackGesture() {
    widget.route.handleCommitBackGesture();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _edge);
}
