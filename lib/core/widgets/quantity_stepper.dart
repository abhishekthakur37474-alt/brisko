import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_motion.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool compact;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 44.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onMinus, size),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          _btn(Icons.add, onPlus, size, filled: true),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, double size, {bool filled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: 18, color: filled ? AppColors.primary : AppColors.black),
      ),
    );
  }
}