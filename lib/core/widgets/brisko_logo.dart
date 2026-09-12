import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class BriskoLogo extends StatelessWidget {
  final double size;
  final bool dark;
  const BriskoLogo({super.key, this.size = 72, this.dark = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? AppColors.black : AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 6))],
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size * 0.58, size * 0.58),
        painter: PizzaSlicePainter(),
      ),
    );
  }
}

class PizzaSlicePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary;
    final path = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 4)
      ..lineTo(2, size.height - 4)
      ..close();
    canvas.drawPath(path, paint);
    final cheese = Paint()..color = const Color(0xFFFFE08A);
    final inner = Path()
      ..moveTo(size.width / 2, size.height * 0.22)
      ..lineTo(size.width * 0.82, size.height * 0.78)
      ..lineTo(size.width * 0.18, size.height * 0.78)
      ..close();
    canvas.drawPath(inner, cheese);
    final pep = Paint()..color = const Color(0xFF8B1A1A);
    canvas.drawCircle(Offset(size.width * 0.46, size.height * 0.46), size.width * 0.07, pep);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.62), size.width * 0.06, pep);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.64), size.width * 0.055, pep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
