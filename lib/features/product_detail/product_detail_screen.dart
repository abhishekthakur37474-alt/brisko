import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pizza_loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/veg_badge.dart';
import '../menu/catalog_providers.dart';
import '../reviews/reviews_controller.dart';
import '../wishlist/wishlist_controller.dart';
import 'customize_sheet.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    final wish = ref.watch(wishlistProvider).valueOrNull ?? {};
    final reviews = ref.watch(reviewsProvider(productId)).valueOrNull ?? [];
    if (product == null) {
      return const Scaffold(body: PizzaLoader(message: 'Loading product...'));
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  actions: [
                    IconButton(
                      tooltip: wish.contains(product.id) ? 'Remove from wishlist' : 'Add to wishlist',
                      onPressed: () => ref.read(wishlistControllerProvider).toggle(product.id),
                      icon: Icon(wish.contains(product.id) ? Icons.favorite : Icons.favorite_border, color: AppColors.primary),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: product.image.isEmpty
                        ? const ColoredBox(color: AppColors.grey)
                        : CachedNetworkImage(imageUrl: product.image, fit: BoxFit.cover),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          VegBadge(isVeg: product.isVeg),
                          const SizedBox(width: 8),
                          Expanded(child: Text(product.name, style: Theme.of(context).textTheme.headlineMedium)),
                        ]),
                        const SizedBox(height: 8),
                        Text(product.description, style: const TextStyle(color: AppColors.muted, height: 1.5)),
                        if (product.avgRating > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                                const SizedBox(width: 4),
                                Text('${product.avgRating} · ${product.reviewCount} reviews', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(rupees(product.basePrice), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22)),
                        if (product.hasCustomizations)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('Customizations available at add to cart', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          ),
                        const SizedBox(height: 22),
                        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
                        if (reviews.isEmpty)
                          const Padding(padding: EdgeInsets.only(top: 8), child: Text('No reviews yet.', style: TextStyle(color: AppColors.muted))),
                        ...reviews.take(5).map((r) => Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${r.userName} · ${r.rating}/5', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(r.comment, style: const TextStyle(color: AppColors.muted)),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: PrimaryButton(
                label: product.hasCustomizations ? 'Customize & add' : 'Add to cart · ${rupees(product.basePrice)}',
                onPressed: () => addProductToCart(context, ref, product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
