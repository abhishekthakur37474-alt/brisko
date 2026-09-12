import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'brisko_logo.dart';

class BriskoRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const BriskoRefresh({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.white,
      displacement: 48,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

class BriskoRefreshSpinner extends StatefulWidget {
  const BriskoRefreshSpinner({super.key});

  @override
  State<BriskoRefreshSpinner> createState() => _BriskoRefreshSpinnerState();
}

class _BriskoRefreshSpinnerState extends State<BriskoRefreshSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: CustomPaint(size: const Size(28, 28), painter: PizzaSlicePainter()),
    );
  }
}