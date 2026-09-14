import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../location/location_controller.dart';
import 'catalog_providers.dart';
import 'category_icon.dart';
import 'menu_filter_row.dart';
import 'product_card.dart';
import 'product_model.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _cat;
  bool _vegOnly = false;
  bool _nonVegOnly = false;
  MenuSort _sort = MenuSort.popularity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters['cat'];
    if (q != null && _cat == null) _cat = q;
  }

  List<ProductModel> _applyFilters(List<ProductModel> products, String? outletId, String? catId) {
    var list = products.where((p) => p.availableAt(outletId)).toList();
    if (catId != null) list = list.where((p) => p.categoryId == catId).toList();
    if (_vegOnly && !_nonVegOnly) {
      list = list.where((p) => p.isVeg).toList();
    } else if (_nonVegOnly && !_vegOnly) {
      list = list.where((p) => !p.isVeg).toList();
    }
    list.sort((a, b) {
      switch (_sort) {
        case MenuSort.priceLowHigh:
          return a.basePrice.compareTo(b.basePrice);
        case MenuSort.priceHighLow:
          return b.basePrice.compareTo(a.basePrice);
        case MenuSort.popularity:
          final featured = (b.isBestSeller ? 2 : 0) + (b.isFeatured ? 1 : 0) - ((a.isBestSeller ? 2 : 0) + (a.isFeatured ? 1 : 0));
          if (featured != 0) return featured;
          final reviews = b.reviewCount.compareTo(a.reviewCount);
          if (reviews != 0) return reviews;
          return b.avgRating.compareTo(a.avgRating);
        case MenuSort.rating:
          final rating = b.avgRating.compareTo(a.avgRating);
          if (rating != 0) return rating;
          return b.reviewCount.compareTo(a.reviewCount);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final productsAsync = ref.watch(productsProvider);
    final outletId = ref.watch(locationControllerProvider).outlet?.id;
    final catId = _cat ?? (cats.isNotEmpty ? cats.first.id : null);
    final wideLayout = catId == 'combos' || catId == 'offers';

    return Scaffold(
      backgroundColor: AppColors.warmBg,
      body: Column(
        children: [
          BriskoTopBar(
            title: 'Menu',
            subtitle: 'Browse the kitchen',
            trailingHugeIcon: HugeIcons.strokeRoundedSearch01,
            onTrailingTap: () => context.push('/search'),
            onBack: () => context.go('/home'),
          ),
          if (cats.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final selected = catId == c.id;
                  return _CategoryPill(
                    label: c.name,
                    icon: CategoryIcon.iconFor(c.id, c.name),
                    selected: selected,
                    onTap: () => setState(() => _cat = c.id),
                  );
                },
              ),
            ),
          MenuFilterRow(
            vegOnly: _vegOnly,
            nonVegOnly: _nonVegOnly,
            onVegToggle: () => setState(() => _vegOnly = !_vegOnly),
            onNonVegToggle: () => setState(() => _nonVegOnly = !_nonVegOnly),
            onSortTap: () async {
              final selected = await showMenuSortSheet(context, _sort);
              if (selected != null && mounted) setState(() => _sort = selected);
            },
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final list = _applyFilters(products, outletId, catId);
                return AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: list.isEmpty
                      ? const EmptyState(
                          key: ValueKey('empty'),
                          title: 'No items',
                          subtitle: 'Nothing in this category for your outlet yet.',
                          icon: Icons.restaurant_outlined,
                        )
                      : KeyedSubtree(
                          key: ValueKey('$catId-$_vegOnly-$_nonVegOnly-$_sort-${list.length}'),
                          child: wideLayout
                              ? ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (_, i) => SizedBox(height: 132, child: ProductCard(product: list[i], wide: true)),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.68,
                                  ),
                                  itemCount: list.length,
                                  itemBuilder: (_, i) => ProductCard(product: list[i]),
                                ),
                        ),
                );
              },
              loading: () => const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 16), child: GridViewDummy()),
              error: (e, _) => const EmptyState(
                title: 'Could not load menu',
                subtitle: 'Check your connection and try again.',
                icon: Icons.wifi_off,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary.withValues(alpha: 0.28) : AppColors.border.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.black,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                height: 1,
              ),
            ),
          ],
        ),
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
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
      childAspectRatio: 0.68,
      children: const [ProductCardSkeleton(), ProductCardSkeleton(), ProductCardSkeleton(), ProductCardSkeleton()],
    );
  }
}
