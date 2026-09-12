import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/brisko_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../location/location_controller.dart';
import '../menu/catalog_providers.dart';
import '../menu/category_icon.dart';
import '../menu/product_card.dart';
import '../notifications/notifications_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  int _banner = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    final productsAsync = ref.watch(productsProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final unread = ref.watch(unreadCountProvider);
    final query = _search.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.grey,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const BriskoLogo(size: 42, dark: false),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.appName,
                                style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                AppStrings.tagline,
                                style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 11, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => context.push('/notifications'),
                          icon: Badge(
                            isLabelVisible: unread > 0,
                            label: Text('$unread'),
                            child: const Icon(Icons.notifications_outlined, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.push('/location'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.address?.fullAddress ?? 'Set delivery location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.white, fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: AppColors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: 'Search pizzas, burgers, sides...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (loc.noCoverage)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EmptyState(
                    title: 'Out of delivery area',
                    subtitle: 'Sorry, Brisko doesn\'t deliver to your area yet. Change your address to continue.',
                    actionLabel: 'Change location',
                    onAction: () => context.push('/location'),
                    icon: Icons.location_off_outlined,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 158,
                    child: PageView(
                      onPageChanged: (i) => setState(() => _banner = i),
                      children: const [
                        _Banner(title: 'Hot. Fresh. Fast.', subtitle: 'Free delivery over Rs 499', color: AppColors.primary, icon: Icons.local_shipping_outlined),
                        _Banner(title: 'Use BRISKO50', subtitle: 'Flat Rs 50 off your next order', color: AppColors.black, icon: Icons.local_offer_outlined),
                        _Banner(title: 'Loyalty rewards', subtitle: 'Earn points on every order', color: Color(0xFF7A1010), icon: Icons.card_giftcard),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _banner == i ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _banner == i ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            catsAsync.when(
              data: (cats) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 118,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final c = cats[i];
                      return GestureDetector(
                        onTap: () => context.go('/menu?cat=${c.id}'),
                        child: SizedBox(
                          width: 76,
                          child: Column(
                            children: [
                              CategoryIcon(category: c),
                              const SizedBox(height: 8),
                              Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Skeleton(height: 80))),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not load categories', style: TextStyle(color: AppColors.muted)),
                ),
              ),
            ),
            productsAsync.when(
              data: (products) {
                var list = products.where((p) => p.availableAt(loc.outlet?.id)).toList();
                if (query.isNotEmpty) {
                  list = list.where((p) => p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query)).toList();
                }
                if (query.isNotEmpty) {
                  if (list.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyState(title: 'No matches', subtitle: 'Try another search term.', icon: Icons.search_off),
                    );
                  }
                  return SliverPadding(
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
                  );
                }
                final bestsellers = list.where((p) => p.isBestSeller).toList();
                final featured = list.where((p) => p.isFeatured).toList();
                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (bestsellers.isNotEmpty) _Section(title: 'Best Sellers', products: bestsellers, onSeeAll: () => context.go('/menu')),
                    if (featured.isNotEmpty) _Section(title: 'Featured', products: featured, onSeeAll: () => context.go('/menu')),
                    if (bestsellers.isEmpty && featured.isEmpty)
                      const EmptyState(title: 'Menu coming soon', subtitle: 'We are baking something good.', icon: Icons.local_pizza_outlined),
                    const SizedBox(height: 24),
                  ]),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(children: [Expanded(child: ProductCardSkeleton()), SizedBox(width: 12), Expanded(child: ProductCardSkeleton())]),
                ),
              ),
              error: (e, _) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyState(title: 'Could not load menu', subtitle: 'Check your connection and try again.', icon: Icons.wifi_off),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _Banner({required this.title, required this.subtitle, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: AppColors.white, fontSize: 14)),
              ],
            ),
          ),
          Icon(icon, color: AppColors.white.withValues(alpha: 0.85), size: 42),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List products;
  final VoidCallback? onSeeAll;
  const _Section({required this.title, required this.products, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, actionLabel: 'See all', onAction: onSeeAll),
        SizedBox(
          height: 268,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: 180, child: ProductCard(product: products[i])),
          ),
        ),
      ],
    );
  }
}
