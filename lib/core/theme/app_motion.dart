import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 250);
  static const Duration modal = Duration(milliseconds: 280);
  static const Duration step = Duration(milliseconds: 600);
  static const Duration heart = Duration(milliseconds: 400);
  static const Duration shimmer = Duration(milliseconds: 1200);
  static const Duration stagger = Duration(milliseconds: 50);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve overshoot = Curves.easeOutBack;
  static const Curve bounce = Curves.elasticOut;

  static Duration reverseOf(Duration d) => Duration(milliseconds: (d.inMilliseconds * 0.65).round());
}

CustomTransitionPage<T> fadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
  Offset begin = const Offset(0.08, 0),
  Duration duration = AppMotion.page,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: AppMotion.reverseOf(duration),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduce = MediaQuery.of(context).disableAnimations;
      if (reduce) return child;
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<T> modalUpPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return fadeSlidePage<T>(
    key: key,
    child: child,
    begin: const Offset(0, 0.08),
    duration: AppMotion.modal,
  );
}