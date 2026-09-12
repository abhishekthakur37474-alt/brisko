import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../addresses/address_model.dart';
import '../location/location_controller.dart';
import '../menu/catalog_providers.dart';
import '../menu/category_icon.dart';
import '../menu/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _banner = 0;

  String _placeName(AddressModel? address) {
    if (address == null) return 'your area';
    final parts = address.fullAddress.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.first;
    if (address.label.isNotEmpty) return address.label;
    return 'your area';
  }

  String _placeLine(AddressModel? address) {
    if (address == null) return 'Set delivery location';
    return address.fullAddress;
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    final productsAsync = ref.watch(productsProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final place = _placeName(loc.address);
    final placeLine = _placeLine(loc.address);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(productsProvider);
            ref.invalidate(categoriesProvider);
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Material(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => context.push('/location'),
                                borderRadius: BorderRadius.circular(16),
                                child: const SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Icon(Icons.location_on, color: AppColors.white, size: 26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/location'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Delivery at $place',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.keyboard_arrow_down, color: AppColors.white, size: 20),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        placeLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: const Color(0xFF2A2A2A),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => context.go('/profile'),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(Icons.person_outline, color: AppColors.white, size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(28),
                                child: InkWell(
                                  onTap: () => context.push('/search'),
                                  borderRadius: BorderRadius.circular(28),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search, color: AppColors.muted, size: 22),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Search for',
                                            style: TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                onTap: () => context.go('/menu'),
                                borderRadius: BorderRadius.circular(22),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Column(
                                    children: [
                                      Icon(Icons.local_pizza_outlined, color: AppColors.black, size: 22),
                                      SizedBox(height: 2),
                                      Text(
                                        'Menu',
                                        style: TextStyle(color: AppColors.black, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                child: FadeSlideIn(
                  delay: AppMotion.stagger,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 168,
                        child: PageView.builder(
                          onPageChanged: (i) => setState(() => _banner = i),
                          itemCount: 3,
                          itemBuilder: (_, i) {
                            const banners = [
                              _Banner(title: 'Hot. Fresh. Fast.', subtitle: 'Free delivery over Rs 499', color: AppColors.primary, icon: Icons.local_shipping_outlined),
                              _Banner(title: 'Use BRISKO50', subtitle: 'Flat Rs 50 off your next order', color: AppColors.black, icon: Icons.local_offer_outlined),
                              _Banner(title: 'Loyalty rewards', subtitle: 'Earn points on every order', color: Color(0xFF7A1010), icon: Icons.card_giftcard),
                            ];
                            return banners[i];
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => AnimatedContainer(
                            duration: AppMotion.fast,
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
              ),
              catsAsync.when(
                data: (cats) => SliverToBoxAdapter(
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: SizedBox(
                      height: 126,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                ),
                loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Skeleton(height: 80))),
                error: (e, _) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Could not load categories', style: TextStyle(color: AppColors.muted)),
                  ),
                ),
              ),
              productsAsync.when(
                data: (products) {
                  final list = products.where((p) => p.availableAt(loc.outlet?.id)).toList();
                  final bestsellers = list.where((p) => p.isBestSeller).toList();
                  final featured = list.where((p) => p.isFeatured).toList();
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (bestsellers.isNotEmpty)
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: _Section(title: 'Best Sellers', products: bestsellers, onSeeAll: () => context.go('/menu')),
                        ),
                      if (featured.isNotEmpty)
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: _Section(title: 'Featured', products: featured, onSeeAll: () => context.go('/menu')),
                        ),
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
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, AppColors.black, 0.28)!],
        ),
        boxShadow: AppColors.softShadow,
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
            padding: const EdgeInsets.fromLTRB(16, 0, 40, 0),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: MediaQuery.of(context).size.width * 0.46, child: ProductCard(product: products[i])),
          ),
        ),
      ],
    );
  }
}