import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/routes/ledgerly_motion.dart';
import 'package:expensetracker_reloaded/routes/predictive_back.dart';
import 'package:expensetracker_reloaded/services/app_settings.dart';

export 'package:expensetracker_reloaded/routes/ledgerly_motion.dart'
    show motionStyles, MotionStyle, MotionGroup, buildMotion;

/// Route animation styles. Saved by name (`AnimationType.<name>`), so the
/// original ten keep their names even where the display name changed
/// (e.g. `morphing` = "Blob Reveal"); never rename or reorder-dependent-save.
enum AnimationType {
  fadeSlide, // Fade Up
  slideLeft, // Slide Left
  slideRight, // Slide Right
  scaleRotate, // Scale + Rotate
  morphing, // Blob Reveal
  bouncy, // Bouncy Pop
  liquid, // Liquid Swipe
  staggered, // Cascade Blinds
  kaleidoscope, // Kaleidoscope
  elasticBounce, // Elastic Drop
  cardStack, // Card Stack (added beta.5)
  sharedAxis, // Shared Axis
  zoomExpand, // Zoom Expand
  circleReveal, // Circle Reveal
  glassBlur, // Glass Blur
  pageFlip, // Page Flip
}

/// Global animation type manager - allows switching between variants.
class AnimationVariants {
  static AnimationType _currentType = AnimationType.fadeSlide;

  static AnimationType get currentType => _currentType;

  static void setAnimationType(AnimationType type) {
    _currentType = type;
  }

  static String getAnimationName(AnimationType type) =>
      motionStyles[type]!.name;

  /// Route for [page] using the current style (or [type]).
  static Route<dynamic> createRoute(Widget page, {AnimationType? type}) {
    // Settings > Enable Animations off: no transition at all (bug #11).
    if (!AppSettings.animations) {
      return LedgerlyPageRoute(
        pageBuilder: (_, _, _) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }
    final t = type ?? _currentType;
    final d = motionStyles[t]!.duration;
    return LedgerlyPageRoute(
      motion: t,
      transitionDuration: d,
      reverseTransitionDuration: d,
      pageBuilder: (_, _, _) => page,
    );
  }
}

/// Ledgerly's page route: opens with the user's chosen animation, and on
/// Android follows the predictive back swipe with the same style in reverse.
///
/// * Opening: the chosen [AnimationType] transition, unchanged.
/// * Back swipe (Android 14+): [RouteBackGestureListener] feeds the finger
///   into the route animation; the selected style plays in reverse and the page
///   behind shows. Let go early = slides back (cancel); far enough = pops.
/// * Back without a swipe (button, Android 13): the style's exit, as before.
/// * Reduce motion / animations off: no transition at all.
class LedgerlyPageRoute<T> extends PageRouteBuilder<T> {
  LedgerlyPageRoute({
    required super.pageBuilder,
    super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.settings,
    this.motion,
  });

  /// Style used for this page; null = use [transitionsBuilder].
  final AnimationType? motion;

  // Keeps the page's state when the wrapper switches between the opening
  // animation and the back-swipe motion.
  final GlobalKey _pageKey = GlobalKey(debugLabel: 'LedgerlyPageRoute.page');

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Theme.of(context).platform != TargetPlatform.android) {
      if (reduceMotion(context)) return child;
      if (motion == null) {
        return super.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );
      }
      return buildMotion(
        motion!,
        animation,
        secondaryAnimation,
        child,
        gesture: () => popGestureInProgress,
      );
    }
    child = KeyedSubtree(key: _pageKey, child: child);
    // The selected style's own transition runs for opening AND for back:
    // during a predictive swipe the route's animation value follows the
    // finger (1 - progress), so the style plays in reverse under the finger;
    // cancel animates it forward to rest, commit finishes the style's exit.
    return RouteBackGestureListener(
      route: this,
      builder: (context, edge) {
        if (reduceMotion(context)) return child;
        if (motion == null) {
          // Custom transitionsBuilder routes (onboarding helpers).
          return super.buildTransitions(
            context,
            animation,
            secondaryAnimation,
            child,
          );
        }
        return buildMotion(
          motion!,
          animation,
          secondaryAnimation,
          child,
          gesture: () => popGestureInProgress,
        );
      },
    );
  }
}
