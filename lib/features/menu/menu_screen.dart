import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../location/location_controller.dart';
import 'catalog_providers.dart';
import 'category_icon.dart';
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
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final selected = (_cat ?? cats.first.id) == c.id;
                  return ChoiceChip(
                    avatar: Icon(
                      CategoryIcon.iconFor(c.id, c.name),
                      size: 16,
                      color: selected ? AppColors.white : AppColors.primary,
                    ),
                    label: Text(c.name),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.white,
                    labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.black, fontWeight: FontWeight.w600),
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() => _cat = c.id),
                    showCheckmark: false,
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                _FilterPill(label: 'All', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterPill(label: 'Veg', selected: _filter == 'veg', onTap: () => setState(() => _filter = 'veg'), color: AppColors.veg),
                const SizedBox(width: 8),
                _FilterPill(label: 'Non-veg', selected: _filter == 'nonveg', onTap: () => setState(() => _filter = 'nonveg'), color: AppColors.nonVeg),
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
                  return const EmptyState(title: 'No items', subtitle: 'Nothing in this category for your outlet yet.', icon: Icons.restaurant_outlined);
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => ProductCard(product: list[i]),
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(16), child: GridViewDummy()),
              error: (e, _) => const EmptyState(title: 'Could not load menu', subtitle: 'Check your connection and try again.', icon: Icons.wifi_off),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterPill({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.black;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.white : AppColors.black, fontWeight: FontWeight.w700, fontSize: 13)),
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
      childAspectRatio: 0.70,
      children: const [ProductCardSkeleton(), ProductCardSkeleton(), ProductCardSkeleton(), ProductCardSkeleton()],
    );
  }
}
