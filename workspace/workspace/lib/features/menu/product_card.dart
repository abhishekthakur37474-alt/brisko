import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import 'product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: product.image.isEmpty
                  ? const ColoredBox(color: AppColors.grey, child: Icon(Icons.local_pizza, color: AppColors.primary, size: 40))
                  : CachedNetworkImage(imageUrl: product.image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegBadge(isVeg: product.isVeg),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('from ${rupees(product.basePrice)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  if (product.avgRating > 0)
                    Text('${product.avgRating.toStringAsFixed(1)} (${product.reviewCount})', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VegBadge extends StatelessWidget {
  final bool isVeg;
  const VegBadge({super.key, required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.veg : AppColors.nonVeg;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.4), borderRadius: BorderRadius.circular(3)),
      alignment: Alignment.center,
      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}
