import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pizza_loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/veg_badge.dart';
import '../menu/catalog_providers.dart';
import '../location/store_closed_banner.dart';
import '../location/store_status.dart';
import '../reviews/review_model.dart';
import '../reviews/reviews_controller.dart';
import '../wishlist/wishlist_controller.dart';
import 'customize_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _scroll = ScrollController();
  bool _elevated = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final next = _scroll.offset > 220;
      if (next != _elevated) setState(() => _elevated = next);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productByIdProvider(widget.productId));
    final wish = ref.watch(wishlistProvider).valueOrNull ?? {};
    final reviews = ref.watch(reviewsProvider(widget.productId)).valueOrNull ?? [];
    if (product == null) {
      return const Scaffold(backgroundColor: AppColors.white, body: PizzaLoader(message: 'Loading product...'));
    }
    final wished = wish.contains(product.id);
    final store = ref.watch(storeStatusProvider);
    final storeClosed = store.isClosed;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  leading: GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: wished ? 'Remove from wishlist' : 'Add to wishlist',
                      onPressed: () => ref.read(wishlistControllerProvider).toggle(product.id),
                      icon: AnimatedScale(
                        scale: wished ? 1.15 : 1,
                        duration: AppMotion.heart,
                        curve: AppMotion.bounce,
                        child: Icon(wished ? Icons.favorite : Icons.favorite_border, color: AppColors.primary),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                      tag: 'product-${product.id}',
                      child: product.image.isEmpty
                          ? const ColoredBox(color: AppColors.grey)
                          : CachedNetworkImage(
                              imageUrl: product.image,
                              fit: BoxFit.cover,
                              memCacheWidth: 900,
                              fadeInDuration: AppMotion.fast,
                            ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const StoreClosedBanner(margin: EdgeInsets.fromLTRB(16, 12, 16, 0)),
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
                        if (product.avgRating > 0)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                              const SizedBox(width: 4),
                              Text('${product.avgRating} · ${product.reviewCount} reviews', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Text(rupees(product.basePrice), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22)),
                        if (product.hasCustomizations) ...[
                          const SizedBox(height: 16),
                          Text('Customize', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...product.sizes.take(3).map((s) => _MiniChip(s.name)),
                              ...product.crusts.take(2).map((s) => _MiniChip(s.name)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Tap Customize to pick size, crust, toppings and add-ons.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              _TabBtn('Details', _tab == 0, () => setState(() => _tab = 0)),
                              _TabBtn('Reviews', _tab == 1, () => setState(() => _tab = 1), count: reviews.length),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: _tab == 0
                              ? Text(product.description, key: const ValueKey('d'), style: const TextStyle(color: AppColors.muted, height: 1.5))
                              : _Reviews(reviews: reviews),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: _elevated ? AppColors.softShadow : const [],
              ),
              child: PrimaryButton(
                label: storeClosed
                    ? 'Closed · Opens ${store.nextOpenLabel ?? 'soon'}'
                    : (product.hasCustomizations ? 'Customize & add' : 'Add to cart · ${rupees(product.basePrice)}'),
                onPressed: storeClosed ? null : () => addProductToCart(context, ref, product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  const _TabBtn(this.label, this.selected, this.onTap, {this.count});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count == null ? label : '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? AppColors.white : AppColors.black, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _Reviews extends StatelessWidget {
  final List<ReviewModel> reviews;
  const _Reviews({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Text('No reviews yet.', key: ValueKey('r0'), style: TextStyle(color: AppColors.muted));
    }
    return Column(
      key: const ValueKey('r1'),
      children: reviews.take(8).map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.userName} · ${r.rating}/5', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(r.comment, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}