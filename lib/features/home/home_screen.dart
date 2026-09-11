import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../location/location_controller.dart';
import '../menu/catalog_providers.dart';
import '../menu/product_card.dart';
import '../notifications/notifications_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

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
                color: AppColors.black,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text('B', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(AppStrings.appName, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: Badge(
                            isLabelVisible: unread > 0,
                            label: Text('$unread'),
                            child: const Icon(Icons.notifications_outlined, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.push('/location'),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              loc.address?.fullAddress ?? 'Set delivery location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppColors.white),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: 'Search pizzas, burgers, sides...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: PageView(
                  children: const [
                    _Banner(title: 'Hot. Fresh. Fast.', subtitle: 'Free delivery over Rs 499', color: AppColors.primary),
                    _Banner(title: 'Use BRISKO50', subtitle: 'Flat Rs 50 off', color: AppColors.black),
                    _Banner(title: 'Loyalty rewards', subtitle: 'Earn points on every order', color: Color(0xFF7A1010)),
                  ],
                ),
              ),
            ),
            catsAsync.when(
              data: (cats) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final c = cats[i];
                      return GestureDetector(
                        onTap: () => context.go('/menu?cat=${c.id}'),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.white,
                              backgroundImage: c.imageUrl.isNotEmpty ? CachedNetworkImageProvider(c.imageUrl) : null,
                              child: c.imageUrl.isEmpty ? const Icon(Icons.local_pizza, color: AppColors.primary) : null,
                            ),
                            const SizedBox(height: 6),
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Skeleton(height: 80))),
              error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
            ),
            productsAsync.when(
              data: (products) {
                var list = products.where((p) => p.availableAt(loc.outlet?.id)).toList();
                if (query.isNotEmpty) {
                  list = list.where((p) => p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query)).toList();
                }
                final bestsellers = list.where((p) => p.isBestSeller).toList();
                final featured = list.where((p) => p.isFeatured).toList();
                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (bestsellers.isNotEmpty) _Section(title: 'Best Sellers', products: bestsellers),
                    if (featured.isNotEmpty) _Section(title: 'Featured', products: featured),
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
              error: (e, _) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text('$e'))),
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
  const _Banner({required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List products;
  const _Section({required this.title, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 230,
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
