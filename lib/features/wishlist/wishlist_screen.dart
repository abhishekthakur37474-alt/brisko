import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../menu/catalog_providers.dart';
import '../menu/product_card.dart';
import 'wishlist_controller.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(wishlistProvider).valueOrNull ?? {};
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final list = products.where((p) => ids.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: list.isEmpty
          ? const EmptyState(title: 'No favorites yet', subtitle: 'Tap the heart on a pizza to save it.', icon: Icons.favorite_border)
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.70, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: list.length,
              itemBuilder: (_, i) => ProductCard(product: list[i]),
            ),
    );
  }
}
