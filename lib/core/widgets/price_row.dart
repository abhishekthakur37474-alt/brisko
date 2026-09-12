import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_motion.dart';

class PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final bool highlight;

  const PriceRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.valueColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyLarge;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: highlight ? AppColors.successSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style?.copyWith(color: bold ? AppColors.text : AppColors.muted))),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Text(
              value,
              key: ValueKey('$label$value'),
              style: style?.copyWith(
                color: valueColor ?? AppColors.text,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}