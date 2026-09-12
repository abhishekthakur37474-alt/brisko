import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'category_model.dart';

class CategoryIcon extends StatelessWidget {
  final CategoryModel category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 68});

  static IconData iconFor(String id, String name) {
    final key = '${id}_${name}'.toLowerCase();
    if (key.contains('beverage') || key.contains('drink')) return Icons.local_drink;
    if (key.contains('burger')) return Icons.lunch_dining;
    if (key.contains('side') || key.contains('fries')) return Icons.fastfood;
    if (key.contains('combo')) return Icons.restaurant;
    if (key.contains('offer')) return Icons.local_offer;
    if (key.contains('pizza')) return Icons.local_pizza;
    return Icons.restaurant_menu;
  }

  @override
  Widget build(BuildContext context) {
    final icon = iconFor(category.id, category.name);
    final fallback = ColoredBox(
      color: AppColors.primarySoft,
      child: Icon(icon, color: AppColors.primary, size: size * 0.42),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: category.imageUrl.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: category.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}
