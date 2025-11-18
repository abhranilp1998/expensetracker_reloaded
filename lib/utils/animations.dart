import 'package:flutter/material.dart';

Route createSlideFadeRoute(Widget page, {int ms = 450}) {
  return PageRouteBuilder(
    transitionDuration: Duration(milliseconds: ms),
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



class AnimatedRoutes {
  static Route createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        final slideIn = Tween(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        
        return FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: animation.drive(slideIn),
            child: child,
          ),
        );
      },
    );
  }
}

class HeroAnimations {
  static Widget logoFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    return ScaleTransition(
      scale: animation.drive(
        Tween(begin: 1.0, end: 0.4).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  static Widget profileFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    return ScaleTransition(
      scale: animation.drive(
        Tween(begin: 0.5, end: 1.5).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
      ),
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(
          Icons.person,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }
}
