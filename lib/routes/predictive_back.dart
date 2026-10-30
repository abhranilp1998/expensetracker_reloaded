import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:expensetracker_reloaded/services/app_settings.dart';

/// True when motion should be skipped (phone reduce-motion or the
/// Settings > Enable Animations switch is off).
bool reduceMotion(BuildContext context) =>
    !AppSettings.animations ||
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

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
