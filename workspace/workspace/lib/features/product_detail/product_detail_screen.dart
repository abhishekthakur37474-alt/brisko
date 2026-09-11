import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pricing.dart';
import '../../core/widgets/pizza_loader.dart';
import '../../core/widgets/primary_button.dart';
import '../cart/cart_controller.dart';
import '../menu/catalog_providers.dart';
import '../menu/product_card.dart';
import '../menu/product_model.dart';
import '../reviews/reviews_controller.dart';
import '../wishlist/wishlist_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _size;
  String? _crust;
  final Set<String> _toppings = {};
  final Set<String> _addons = {};
  int _qty = 1;
  bool _adding = false;

  double _price(ProductModel p) {
    double sizeMod = 0;
    double crustMod = 0;
    if (_size != null) {
      sizeMod = p.sizes.where((s) => s.id == _size).firstOrNull?.price ?? 0;
    }
    if (_crust != null) {
      crustMod = p.crusts.where((s) => s.id == _crust).firstOrNull?.price ?? 0;
    }
    final toppings = p.toppings.where((t) => _toppings.contains(t.id)).fold<double>(0, (s, t) => s + t.price);
    final addons = p.addons.where((t) => _addons.contains(t.id)).fold<double>(0, (s, t) => s + t.price);
    return Pricing.itemPrice(basePrice: p.basePrice, sizeModifier: sizeMod, crustModifier: crustMod, toppingsTotal: toppings, addonsTotal: addons);
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productByIdProvider(widget.productId));
    final wish = ref.watch(wishlistProvider).valueOrNull ?? {};
    final reviews = ref.watch(reviewsProvider(widget.productId)).valueOrNull ?? [];
    if (product == null) {
      return const Scaffold(body: PizzaLoader(message: 'Loading product...'));
    }
    _size ??= product.sizes.isNotEmpty ? product.sizes.first.id : null;
    _crust ??= product.crusts.isNotEmpty ? product.crusts.first.id : null;
    final unit = _price(product);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  actions: [
                    IconButton(
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
                        Row(children: [VegBadge(isVeg: product.isVeg), const SizedBox(width: 8), Expanded(child: Text(product.name, style: Theme.of(context).textTheme.headlineMedium))]),
                        const SizedBox(height: 8),
                        Text(product.description),
                        if (product.avgRating > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${product.avgRating} · ${product.reviewCount} reviews', style: const TextStyle(color: AppColors.muted)),
                          ),
                        if (product.sizes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Size', style: Theme.of(context).textTheme.titleMedium),
                          Wrap(
                            spacing: 8,
                            children: product.sizes
                                .map((s) => ChoiceChip(
                                      label: Text('${s.name}${s.price > 0 ? ' +${rupees(s.price)}' : ''}'),
                                      selected: _size == s.id,
                                      onSelected: (_) => setState(() => _size = s.id),
                                    ))
                                .toList(),
                          ),
                        ],
                        if (product.crusts.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Crust', style: Theme.of(context).textTheme.titleMedium),
                          Wrap(
                            spacing: 8,
                            children: product.crusts
                                .map((s) => ChoiceChip(
                                      label: Text('${s.name}${s.price > 0 ? ' +${rupees(s.price)}' : ''}'),
                                      selected: _crust == s.id,
                                      onSelected: (_) => setState(() => _crust = s.id),
                                    ))
                                .toList(),
                          ),
                        ],
                        if (product.toppings.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Toppings', style: Theme.of(context).textTheme.titleMedium),
                          Wrap(
                            spacing: 8,
                            children: product.toppings
                                .map((s) => FilterChip(
                                      label: Text('${s.name} +${rupees(s.price)}'),
                                      selected: _toppings.contains(s.id),
                                      onSelected: (v) => setState(() => v ? _toppings.add(s.id) : _toppings.remove(s.id)),
                                    ))
                                .toList(),
                          ),
                        ],
                        if (product.addons.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Add-ons', style: Theme.of(context).textTheme.titleMedium),
                          Wrap(
                            spacing: 8,
                            children: product.addons
                                .map((s) => FilterChip(
                                      label: Text('${s.name} +${rupees(s.price)}'),
                                      selected: _addons.contains(s.id),
                                      onSelected: (v) => setState(() => v ? _addons.add(s.id) : _addons.remove(s.id)),
                                    ))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
                        if (reviews.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No reviews yet.')),
                        ...reviews.take(5).map((r) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${r.userName} · ${r.rating}/5'),
                              subtitle: Text(r.comment),
                            )),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))]),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => setState(() { if (_qty > 1) _qty--; }), icon: const Icon(Icons.remove)),
                      Text('$_qty', style: Theme.of(context).textTheme.titleMedium),
                      IconButton(onPressed: () => setState(() => _qty++), icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Add ${rupees(unit * _qty)}',
                    loading: _adding,
                    onPressed: () async {
                      setState(() => _adding = true);
                      try {
                        final toppings = {for (final t in product.toppings.where((t) => _toppings.contains(t.id))) t.name: t.price};
                        final addons = {for (final t in product.addons.where((t) => _addons.contains(t.id))) t.name: t.price};
                        await ref.read(cartControllerProvider).addCustomized(
                              productId: product.id,
                              name: product.name,
                              image: product.image,
                              isVeg: product.isVeg,
                              unitPrice: unit,
                              selectedSize: product.sizes.where((s) => s.id == _size).firstOrNull?.name ?? '',
                              selectedCrust: product.crusts.where((s) => s.id == _crust).firstOrNull?.name ?? '',
                              toppings: toppings,
                              addons: addons,
                              quantity: _qty,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                          context.pop();
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      } finally {
                        if (mounted) setState(() => _adding = false);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
