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
  /// ANIMATION 4: Smooth Expand In (modern, subtle)
  /// ============================================================
  static Route<dynamic> _scaleRotateRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad));
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
  /// ANIMATION 5: Smooth Vertical Swipe (modern, fluid)
  /// ============================================================
  static Route<dynamic> _morphingRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(0.0, 0.15), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 6: Slide + Fade Left (sleek, modern)
  /// ============================================================
  static Route<dynamic> _bouncyRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(-0.3, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 7: Slide + Fade Right (smooth, modern)
  /// ============================================================
  static Route<dynamic> _liquidRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(begin: const Offset(0.3, 0.0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutQuad));
      
      final fadeTween = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOut));

      final progress = animation.value;
      
      // Slow phase: 0% to 15%, quick phase: 15% to 85%, rest: 85% to 100%
      double smoothedProgress = progress;
      if (progress < 0.15) {
        // Slow acceleration phase: 0% to 15%
        smoothedProgress = (progress / 0.15) * 0.15;
      } else if (progress < 0.85) {
        // Quick animation phase: 15% to 85%
        smoothedProgress = 0.15 + ((progress - 0.15) / 0.70) * 0.70;
      } else {
        // Resting phase: 85% to 100%
        smoothedProgress = 0.85 + ((progress - 0.85) / 0.15) * 0.15;
      }

      final smoothAnimation = AlwaysStoppedAnimation<double>(smoothedProgress);

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
        position: smoothAnimation.drive(slideTween),
        child: child,
        ),
      );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 8: Smooth Diagonal Swipe (flowing, elegant)
  /// ============================================================
  static Route<dynamic> _staggeredRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(-0.15, 0.1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// ============================================================
  /// ANIMATION 9: Smooth Scale Bloom (modern, bright entry)
  /// ============================================================
  static Route<dynamic> _kaleidoscopeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.7, end: 1.0)
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
  /// ANIMATION 10: Smooth Tilt Entry (sophisticated, modern)
  /// ============================================================
  static Route<dynamic> _elasticBounceRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(0.15, -0.1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
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
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad));
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

  /// Create morphing blob route
  static Route<T> morphing<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(0.0, 0.15), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Create bouncy scale route
  static Route<T> bouncy<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(-0.3, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Create liquid swipe route
  static Route<T> liquid<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Create custom curve with stops at 22% and 77% for smooth effect
        final customCurve = Interval(0.0, 1.0, curve: Curves.easeOutQuad);
        
        final slideTween = Tween(begin: const Offset(0.3, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: customCurve));
        
        // Fade with smooth stops - quick fade at 22%, holds, then final push at 77%
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        // Get animation value and apply custom timing for smooth stops effect
        final progress = animation.value;
        
        // Smooth acceleration/deceleration at key points (22% and 77%)
        double smoothedProgress = progress;
        if (progress < 0.22) {
          // Acceleration phase: 0% to 22%
          smoothedProgress = (progress / 0.22) * 0.22;
        } else if (progress < 0.77) {
          // Holding phase: 22% to 77% (smooth mid-point)
          smoothedProgress = 0.22 + ((progress - 0.22) / 0.55) * 0.55;
        } else {
          // Final push phase: 77% to 100%
          smoothedProgress = 0.77 + ((progress - 0.77) / 0.23) * 0.23;
        }

        final smoothAnimation = AlwaysStoppedAnimation<double>(smoothedProgress);

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: smoothAnimation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Create staggered cascade route
  static Route<T> staggered<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(-0.15, 0.1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Create kaleidoscope route
  static Route<T> kaleidoscope<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.7, end: 1.0)
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

  /// Create elastic bounce route
  static Route<T> elasticBounce<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: const Offset(0.15, -0.1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutQuad));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }
}
