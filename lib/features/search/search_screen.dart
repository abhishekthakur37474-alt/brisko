import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../location/location_controller.dart';
import '../menu/catalog_providers.dart';
import '../menu/product_card.dart';
import '../menu/product_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  List<ProductModel> _filter(List<ProductModel> products, Map<String, String> catNames) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return const [];
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return products.where((p) {
      final hay = [
        p.name,
        p.description,
        p.categoryId,
        catNames[p.categoryId] ?? '',
        ...p.sizes.map((e) => e.name),
        ...p.crusts.map((e) => e.name),
        ...p.toppings.map((e) => e.name),
        ...p.addons.map((e) => e.name),
      ].join(' ').toLowerCase();
      return words.every(hay.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    final productsAsync = ref.watch(productsProvider);
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catNames = {for (final c in cats) c.id: c.name};

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
          cursorColor: AppColors.white,
          decoration: const InputDecoration(
            hintText: 'Search for pizzas, burgers...',
            hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontWeight: FontWeight.w500),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
                _focus.requestFocus();
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final available = products.where((p) => p.availableAt(loc.outlet?.id)).toList();
          if (_query.isEmpty) {
            return const EmptyState(
              title: 'Search the menu',
              subtitle: 'Try pizza, burger, garlic bread, or a topping name.',
              icon: Icons.search,
            );
          }
          final matches = _filter(available, catNames);
          final showingMenu = matches.isEmpty;
          final list = showingMenu ? available : matches;
          if (list.isEmpty) {
            return EmptyState(
              title: 'Menu coming soon',
              subtitle: 'Nothing to show for your outlet yet.',
              actionLabel: 'Go to menu',
              onAction: () => context.go('/menu'),
              icon: Icons.restaurant_outlined,
            );
          }
          return CustomScrollView(
            slivers: [
              if (showingMenu)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No matches for "$_query"',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Showing the full menu instead.',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${list.length} result${list.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.70,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ProductCard(product: list[i]),
                    childCount: list.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [Expanded(child: ProductCardSkeleton()), SizedBox(width: 12), Expanded(child: ProductCardSkeleton())]),
        ),
        error: (e, _) => const EmptyState(
          title: 'Could not search',
          subtitle: 'Check your connection and try again.',
          icon: Icons.wifi_off,
        ),
      ),
    );
  }
}
