import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/glass_sheet.dart';
import '../addresses/address_controller.dart';
import '../addresses/address_model.dart';
import '../location/location_controller.dart';
import '../menu/catalog_providers.dart';
import '../menu/category_icon.dart';
import '../menu/product_card.dart';
import '../offers_coupons/coupon_controller.dart';
import '../offers_coupons/coupon_model.dart';

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

  Future<void> _openAddressPicker() async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (c) => _AddressPickerSheet(
        onAddNew: () {
          Navigator.pop(c);
          context.push('/addresses');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    final productsAsync = ref.watch(productsProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final coupons = ref.watch(couponsProvider).valueOrNull ?? [];
    final place = _placeName(loc.address);
    final placeLine = _placeLine(loc.address);

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        color: AppColors.primary,
        displacement: topInset + 72,
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(couponsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _CollapsingHomeHeader(
                topInset: topInset,
                place: place,
                placeLine: placeLine,
                onLocation: _openAddressPicker,
                onSearch: () => context.push('/search'),
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
              // Banner carousel — commented out per request.
              // SliverToBoxAdapter(
              //   child: FadeSlideIn(
              //     delay: AppMotion.stagger,
              //     child: Column(
              //       children: [
              //         SizedBox(
              //           height: 168,
              //           child: PageView.builder(
              //             onPageChanged: (i) => setState(() => _banner = i),
              //             itemCount: 3,
              //             itemBuilder: (_, i) {
              //               const banners = [
              //                 _Banner(title: 'Hot. Fresh. Fast.', subtitle: 'Free delivery over Rs 499', color: AppColors.primary, icon: Icons.local_shipping_outlined),
              //                 _Banner(title: 'Use BRISKO50', subtitle: 'Flat Rs 50 off your next order', color: AppColors.black, hugeIcon: HugeIcons.strokeRoundedDiscount01),
              //                 _Banner(title: 'Loyalty rewards', subtitle: 'Earn points on every order', color: Color(0xFF7A1010), icon: Icons.card_giftcard),
              //               ];
              //               return banners[i];
              //             },
              //           ),
              //         ),
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: List.generate(
              //             3,
              //             (i) => AnimatedContainer(
              //               duration: AppMotion.fast,
              //               margin: const EdgeInsets.symmetric(horizontal: 3),
              //               width: _banner == i ? 18 : 7,
              //               height: 7,
              //               decoration: BoxDecoration(
              //                 color: _banner == i ? AppColors.primary : AppColors.border,
              //                 borderRadius: BorderRadius.circular(8),
              //               ),
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
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
                      if (coupons.isNotEmpty)
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 250),
                          child: _OffersForYou(coupons: coupons),
                        ),
                      if (bestsellers.isEmpty && featured.isEmpty)
                        const EmptyState(title: 'Menu coming soon', subtitle: 'We are baking something good.', icon: Icons.local_pizza_outlined),
                      const SizedBox(height: 140),
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

class _CollapsingHomeHeader extends SliverPersistentHeaderDelegate {
  final double topInset;
  final String place;
  final String placeLine;
  final VoidCallback onLocation;
  final VoidCallback onSearch;

  _CollapsingHomeHeader({
    required this.topInset,
    required this.place,
    required this.placeLine,
    required this.onLocation,
    required this.onSearch,
  });

  static const double _expandedBody = 156;
  static const double _collapsedBody = 72;

  @override
  double get maxExtent => topInset + _expandedBody;

  @override
  double get minExtent => topInset + _collapsedBody;

  @override
  bool shouldRebuild(covariant _CollapsingHomeHeader oldDelegate) {
    return oldDelegate.topInset != topInset ||
        oldDelegate.place != place ||
        oldDelegate.placeLine != placeLine;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = (maxExtent - minExtent).clamp(1.0, 400.0);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final locationOpacity = (1 - t * 1.35).clamp(0.0, 1.0);
    final bottomRadius = 24 * (1 - t);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
          boxShadow: t > 0.35
              ? const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))]
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              right: 16,
              top: topInset + 8,
              child: IgnorePointer(
                ignoring: locationOpacity < 0.05,
                child: Opacity(
                  opacity: locationOpacity,
                  child: Transform.translate(
                    offset: Offset(0, -12 * t),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onLocation,
                          behavior: HitTestBehavior.opaque,
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation04,
                            color: AppColors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: onLocation,
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(28),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.muted, size: 22),
                        SizedBox(width: 10),
                        Expanded(child: _RotatingSearchHint()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotatingSearchHint extends StatefulWidget {
  const _RotatingSearchHint();

  @override
  State<_RotatingSearchHint> createState() => _RotatingSearchHintState();
}

class _RotatingSearchHintState extends State<_RotatingSearchHint> {
  static const _names = ['Farmhouse', 'Beverages', 'BBQ', 'What Do You Want?', 'Brisko'];
  static const _hintStyle = TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w600);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _index = (_index + 1) % _names.length);
    Future<void>.delayed(const Duration(milliseconds: 2200), _tick);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Search for ',
          style: TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        Flexible(
          child: ClipRect(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Opacity(
                  opacity: 0,
                  child: Text(
                    _names.reduce((a, b) => a.length >= b.length ? a : b),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _hintStyle,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.7), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _names[_index],
                    key: ValueKey(_index),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _hintStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData? icon;
  final List<List<dynamic>>? hugeIcon;
  const _Banner({required this.title, required this.subtitle, required this.color, this.icon, this.hugeIcon});

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
          if (hugeIcon != null)
            HugeIcon(icon: hugeIcon!, color: AppColors.white.withValues(alpha: 0.85), size: 42)
          else if (icon != null)
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

class _OffersForYou extends StatefulWidget {
  final List<CouponModel> coupons;
  const _OffersForYou({required this.coupons});

  @override
  State<_OffersForYou> createState() => _OffersForYouState();
}

class _OffersForYouState extends State<_OffersForYou> {
  late final PageController _page;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.88);
    if (widget.coupons.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_page.hasClients) return;
        final next = (_index + 1) % widget.coupons.length;
        _page.animateToPage(next, duration: AppMotion.page, curve: AppMotion.easeOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Offers for you', actionLabel: 'See all', onAction: () => context.push('/offers')),
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _page,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.coupons.length,
            itemBuilder: (_, i) {
              final c = widget.coupons[i];
              final selected = i == _index;
              return AnimatedScale(
                scale: selected ? 1 : 0.96,
                duration: AppMotion.fast,
                child: _OfferCard(coupon: c),
              );
            },
          ),
        ),
        if (widget.coupons.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.coupons.length,
                (i) => AnimatedContainer(
                  duration: AppMotion.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _index == i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _index == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final CouponModel coupon;
  const _OfferCard({required this.coupon});

  String get _valueLabel {
    if (coupon.discountType == 'percent') {
      return '${coupon.discountValue.toStringAsFixed(0)}% OFF';
    }
    return 'Rs ${coupon.discountValue.toStringAsFixed(0)} OFF';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE30613), Color(0xFF8B0A12)],
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Clipboard.setData(ClipboardData(text: coupon.code));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${coupon.code} copied')));
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedDiscount01, color: AppColors.white, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        coupon.code,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.white.withValues(alpha: 0.88), fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Min order Rs ${coupon.minOrderValue.toStringAsFixed(0)}',
                        style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _valueLabel,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Tap to copy',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressPickerSheet extends ConsumerWidget {
  final VoidCallback onAddNew;
  const _AddressPickerSheet({required this.onAddNew});

  bool _isSelected(AddressModel address, AddressModel? current) {
    if (current == null) return false;
    if (address.id.isNotEmpty && current.id == address.id) return true;
    return address.fullAddress == current.fullAddress;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider).valueOrNull ?? [];
    final current = ref.watch(locationControllerProvider).address;
    final outlets = ref.watch(outletsProvider).valueOrNull ?? [];
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select delivery address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No saved addresses yet',
                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final a = addresses[i];
                  final selected = _isSelected(a, current);
                  return Material(
                    color: selected ? AppColors.primarySoft : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ref.read(locationControllerProvider.notifier).setFromSaved(a, outlets);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation04,
                              color: selected ? AppColors.primary : AppColors.black,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          a.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: selected ? AppColors.primary : AppColors.black,
                                          ),
                                        ),
                                      ),
                                      if (a.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successSoft,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Default',
                                            style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.fullAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onAddNew,
              child: const Text('Add new address'),
            ),
          ),
        ],
      ),
    );
  }
}