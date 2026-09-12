import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'brisko_logo.dart';

class PizzaLoader extends StatefulWidget {
  final String? message;
  const PizzaLoader({super.key, this.message});

  @override
  State<PizzaLoader> createState() => _PizzaLoaderState();
}

class _PizzaLoaderState extends State<PizzaLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: CustomPaint(size: const Size(56, 56), painter: PizzaSlicePainter()),
          ),
          const SizedBox(height: 12),
          Text(
            widget.message ?? AppStrings.tagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
