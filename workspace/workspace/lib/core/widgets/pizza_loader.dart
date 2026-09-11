import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
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
            child: CustomPaint(size: const Size(56, 56), painter: _PizzaSlicePainter()),
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

class _PizzaSlicePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary;
    final path = Path()
      ..moveTo(size.width / 2, 4)
      ..lineTo(size.width - 4, size.height - 6)
      ..lineTo(4, size.height - 6)
      ..close();
    canvas.drawPath(path, paint);
    final pep = Paint()..color = const Color(0xFF8B1A1A);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.42), 4, pep);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.58), 3.5, pep);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.62), 3, pep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
