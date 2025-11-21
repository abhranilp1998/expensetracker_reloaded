import 'package:flutter/material.dart';

/// Enumeration of available route animation variants
enum AnimationType {
  fadeSlide,      // Fade + Slide from bottom
  slideLeft,      // Slide from left
  slideRight,     // Slide from right
  scaleRotate,    // Scale + Rotate animation
  morphing,       // Morphing blob animation (modern)
  bouncy,         // Bouncy scale animation
  liquid,         // Liquid swipe effect
  staggered,      // Staggered cascade animation
  kaleidoscope,   // Rotating kaleidoscope effect
  elasticBounce,  // Elastic bounce with overshoot
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
      case AnimationType.morphing:
        return 'Morphing Blob';
      case AnimationType.bouncy:
        return 'Bouncy Scale';
      case AnimationType.liquid:
        return 'Liquid Swipe';
      case AnimationType.staggered:
        return 'Staggered Cascade';
      case AnimationType.kaleidoscope:
        return 'Kaleidoscope';
      case AnimationType.elasticBounce:
        return 'Elastic Bounce';
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
    AnimationType.morphing: _morphingRoute,
    AnimationType.bouncy: _bouncyRoute,
    AnimationType.liquid: _liquidRoute,
    AnimationType.staggered: _staggeredRoute,
    AnimationType.kaleidoscope: _kaleidoscopeRoute,
    AnimationType.elasticBounce: _elasticBounceRoute,
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

  /// ============================================================
  /// ANIMATION 5: Morphing Blob (modern, organic)
  /// ============================================================
  static Route<dynamic> _morphingRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));
        final rotateTween = Tween(begin: 0.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: Transform.rotate(
            angle: animation.drive(rotateTween).value * 3.14159,
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 6: Bouncy Scale (playful, springy)
  /// ============================================================
  static Route<dynamic> _bouncyRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 7: Liquid Swipe (sleek, modern effect)
  /// ============================================================
  static Route<dynamic> _liquidRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutQuad));
        final fadeTween = Tween(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));
        final rotateTween = Tween(begin: -0.1, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: Transform.rotate(
            angle: animation.drive(rotateTween).value * 3.14159,
            child: SlideTransition(
              position: animation.drive(slideTween),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 8: Staggered Cascade (elegant, flowing)
  /// ============================================================
  static Route<dynamic> _staggeredRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideYTween = Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final slideXTween = Tween(begin: const Offset(-0.2, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideYTween),
            child: Transform.translate(
              offset: slideXTween.evaluate(animation) * 100,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 9: Kaleidoscope (vibrant, rotating spiral)
  /// ============================================================
  static Route<dynamic> _kaleidoscopeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 750),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final rotateTween = Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: Transform.rotate(
            angle: animation.drive(rotateTween).value * 3.14159 * 2,
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 10: Elastic Bounce (energetic, snappy)
  /// ============================================================
  static Route<dynamic> _elasticBounceRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
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

  /// Create morphing blob route
  static Route<T> morphing<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));
        final rotateTween = Tween(begin: 0.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: Transform.rotate(
            angle: animation.drive(rotateTween).value * 3.14159,
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Create bouncy scale route
  static Route<T> bouncy<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Create liquid swipe route
  static Route<T> liquid<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutQuad));
        final fadeTween = Tween(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));
        final rotateTween = Tween(begin: -0.1, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: Transform.rotate(
            angle: animation.drive(rotateTween).value * 3.14159,
            child: SlideTransition(
              position: animation.drive(slideTween),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Create staggered cascade route
  static Route<T> staggered<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideYTween = Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final slideXTween = Tween(begin: const Offset(-0.2, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideYTween),
            child: Transform.translate(
              offset: slideXTween.evaluate(animation) * 100,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Create kaleidoscope route
  static Route<T> kaleidoscope<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 750),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final rotateTween = Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: Transform.rotate(
            angle: animation.drive(rotateTween).value * 3.14159 * 2,
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Create elastic bounce route
  static Route<T> elasticBounce<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }
}
