import 'package:flutter/material.dart';

/// Enumeration of available route animation variants
enum AnimationType {
  fadeSlide,      // Fade + Slide from bottom
  slideLeft,      // Slide from left
  slideRight,     // Slide from right
  scaleRotate,    // Scale + Rotate animation
}

/// Global animation type manager - allows switching between variants
class AnimationVariants {
  static AnimationType _currentType = AnimationType.fadeSlide;

  /// Get currently selected animation type
  static AnimationType get currentType => _currentType;

  /// Set animation type globally
  static void setAnimationType(AnimationType type) {
    _currentType = type;
  }

  /// Get human-readable name for animation type
  static String getAnimationName(AnimationType type) {
    switch (type) {
      case AnimationType.fadeSlide:
        return 'Fade + Slide';
      case AnimationType.slideLeft:
        return 'Slide Left';
      case AnimationType.slideRight:
        return 'Slide Right';
      case AnimationType.scaleRotate:
        return 'Scale + Rotate';
    }
  }

  /// Create route with current animation type
  static Route<dynamic> createRoute(Widget page) {
    return _routeBuilders[_currentType]!(page);
  }

  /// Map of animation builders - one for each type
  static final Map<AnimationType, Function(Widget)> _routeBuilders = {
    AnimationType.fadeSlide: _fadeSlideRoute,
    AnimationType.slideLeft: _slideLeftRoute,
    AnimationType.slideRight: _slideRightRoute,
    AnimationType.scaleRotate: _scaleRotateRoute,
  };

  /// ============================================================
  /// ANIMATION 1: Fade + Slide (Original - smooth entry)
  /// ============================================================
  static Route<dynamic> _fadeSlideRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 2: Slide from Left (quick, modern)
  /// ============================================================
  static Route<dynamic> _slideLeftRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 3: Slide from Right (reverse direction)
  /// ============================================================
  static Route<dynamic> _slideRightRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 4: Scale + Rotate (playful, modern)
  /// ============================================================
  static Route<dynamic> _scaleRotateRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Scale animation: start from 0.8, end at 1.0
        final scaleTween = Tween(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        // Rotation animation: start from -0.05, end at 0.0
        final rotateTween = Tween(begin: -0.05, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        // Fade animation for opacity
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: Transform.rotate(
              angle: animation.drive(rotateTween).value * 3.14159,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Alternative: Create custom routes with specified animation type
class CustomAnimationRoute {
  /// Create fade + slide route
  static Route<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: animation.drive(tween), child: child),
        );
      },
    );
  }

  /// Create slide left route
  static Route<T> slideLeft<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Create slide right route
  static Route<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Create scale + rotate route
  static Route<T> scaleRotate<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final rotateTween = Tween(begin: -0.05, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: Transform.rotate(
              angle: animation.drive(rotateTween).value * 3.14159,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
