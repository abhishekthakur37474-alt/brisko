import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../location/location_controller.dart';
import 'catalog_providers.dart';
import 'product_card.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _cat;
  String _filter = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['cat'];
    if (q != null && _cat == null) _cat = q;
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final productsAsync = ref.watch(productsProvider);
    final outletId = ref.watch(locationControllerProvider).outlet?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Column(
        children: [
          if (cats.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final selected = (_cat ?? cats.first.id) == c.id;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.black, fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _cat = c.id),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(label: const Text('All'), selected: _filter == 'all', onSelected: (_) => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Veg'), selected: _filter == 'veg', onSelected: (_) => setState(() => _filter = 'veg')),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Non-veg'), selected: _filter == 'nonveg', onSelected: (_) => setState(() => _filter = 'nonveg')),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final catId = _cat ?? (cats.isNotEmpty ? cats.first.id : null);
                var list = products.where((p) => p.availableAt(outletId)).toList();
                if (catId != null) list = list.where((p) => p.categoryId == catId).toList();
                if (_filter == 'veg') list = list.where((p) => p.isVeg).toList();
                if (_filter == 'nonveg') list = list.where((p) => !p.isVeg).toList();
                if (list.isEmpty) {
                  return const EmptyState(title: 'No items', subtitle: 'Nothing in this category for your outlet yet.');
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => ProductCard(product: list[i]),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: GridViewDummy(),
              ),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class GridViewDummy extends StatelessWidget {
  const GridViewDummy({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: const [ProductCardSkeleton(), ProductCardSkeleton(), ProductCardSkeleton(), ProductCardSkeleton()],
    );
  }
}
