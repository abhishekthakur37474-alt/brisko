import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class VegBadge extends StatelessWidget {
  final bool isVeg;
  const VegBadge({super.key, required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.veg : AppColors.nonVeg;
    return Semantics(
      label: isVeg ? 'Vegetarian' : 'Non vegetarian',
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(border: Border.all(color: color, width: 1.4), borderRadius: BorderRadius.circular(3)),
        alignment: Alignment.center,
        child: Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}
