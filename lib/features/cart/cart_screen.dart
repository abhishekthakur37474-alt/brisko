import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/price_row.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../offers_coupons/coupon_controller.dart';
import '../location/store_closed_banner.dart';
import '../location/store_status.dart';
import 'cart_controller.dart';
import 'cart_item.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  String? _couponMsg;
  bool _applying = false;
  bool _couponFlash = false;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider).valueOrNull ?? [];
    final price = ref.watch(priceBreakdownProvider);
    final coupon = ref.watch(appliedCouponProvider);
    final storeClosed = ref.watch(storeStatusProvider).isClosed;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          BriskoTopBar(
            title: 'Cart',
            subtitle: items.isEmpty ? 'Add something tasty' : 'Review your items',
            trailingIcon: items.isEmpty ? null : Icons.delete_outline,
            onTrailingTap: items.isEmpty
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Clear cart?'),
                        content: const Text('This will remove all items from your cart.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (ok == true) await ref.read(cartControllerProvider).clear();
                  },
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          const StoreClosedBanner(),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    title: 'Cart is empty',
                    subtitle: 'Add a pizza and we will fire up the oven.',
                    actionLabel: 'Browse menu',
                    onAction: () => context.go('/menu'),
                    icon: Icons.shopping_bag_outlined,
                  )
                : Column(
                    children: [
                      Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: items.length + 2,
                    itemBuilder: (context, i) {
                      if (i < items.length) {
                        final item = items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.delete_outline, color: AppColors.white),
                            ),
                            onDismissed: (_) => ref.read(cartControllerProvider).remove(item.id),
                            child: _CartLine(item: item),
                          ),
                        );
                      }
                      if (i == items.length) {
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Coupon', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _coupon,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Coupon code',
                                  suffixIcon: TextButton(
                                    onPressed: _applying
                                        ? null
                                        : () async {
                                            setState(() => _applying = true);
                                            try {
                                              final c = await ref.read(applyCouponProvider).apply(_coupon.text);
                                              setState(() {
                                                _couponMsg = c.description;
                                                _couponFlash = true;
                                              });
                                              Future<void>.delayed(const Duration(milliseconds: 700), () {
                                                if (mounted) setState(() => _couponFlash = false);
                                              });
                                            } catch (e) {
                                              setState(() => _couponMsg = e.toString().replaceAll('Exception: ', ''));
                                            } finally {
                                              if (mounted) setState(() => _applying = false);
                                            }
                                          },
                                    child: Text(_applying ? '...' : 'Apply'),
                                  ),
                                ),
                              ),
                              if (coupon != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Applied: ${coupon.code}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                                ),
                              if (_couponMsg != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_couponMsg!)),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 88),
                        child: AppCard(
                          child: Column(
                            children: [
                              PriceRow('Subtotal', rupees(price.subtotal)),
                              PriceRow('GST (5%)', rupees(price.gstAmount)),
                              PriceRow('Delivery', price.deliveryCharge == 0 ? 'FREE' : rupees(price.deliveryCharge), valueColor: price.deliveryCharge == 0 ? AppColors.success : null),
                              const SizedBox(height: 8),
                              if (price.couponDiscount > 0) PriceRow('Coupon', '- ${rupees(price.couponDiscount)}', valueColor: AppColors.success, highlight: _couponFlash),
                              if (price.loyaltyDiscount > 0) PriceRow('Loyalty', '- ${rupees(price.loyaltyDiscount)}', valueColor: AppColors.success),
                              const Divider(height: 20),
                              PriceRow('Total', rupees(price.finalAmount), bold: true),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      boxShadow: AppColors.softShadow,
                    ),
                    child: PrimaryButton(label: 'Proceed to Checkout · ${rupees(price.finalAmount)}', onPressed: storeClosed ? null : () => context.push('/checkout')),
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

class _CartLine extends ConsumerWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = [item.selectedSize, item.selectedCrust].where((e) => e.isNotEmpty).join(' · ');
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image.isEmpty
                ? const SizedBox(width: 72, height: 72, child: ColoredBox(color: AppColors.grey, child: Icon(Icons.local_pizza)))
                : CachedNetworkImage(imageUrl: item.image, width: 72, height: 72, fit: BoxFit.cover, memCacheWidth: 180, fadeInDuration: AppMotion.fast),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.grey, borderRadius: BorderRadius.circular(20)),
                    child: Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(rupees(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    QuantityStepper(
                      compact: true,
                      value: item.quantity,
                      onMinus: () => ref.read(cartControllerProvider).setQuantity(item, item.quantity - 1),
                      onPlus: () => ref.read(cartControllerProvider).setQuantity(item, item.quantity + 1),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref.read(cartControllerProvider).remove(item.id),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}