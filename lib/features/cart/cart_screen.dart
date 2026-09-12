import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/price_row.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../offers_coupons/coupon_controller.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  String? _couponMsg;
  bool _applying = false;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: items.isEmpty
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.image.isEmpty
                                        ? const SizedBox(width: 72, height: 72, child: ColoredBox(color: AppColors.grey, child: Icon(Icons.local_pizza)))
                                        : CachedNetworkImage(imageUrl: item.image, width: 72, height: 72, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                                        if (item.selectedSize.isNotEmpty || item.selectedCrust.isNotEmpty)
                                          Text(
                                            [item.selectedSize, item.selectedCrust].where((e) => e.isNotEmpty).join(' · '),
                                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                          ),
                                        const SizedBox(height: 4),
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
                            ),
                          )),
                      AppCard(
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
                                            setState(() => _couponMsg = c.description);
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
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          children: [
                            PriceRow('Subtotal', rupees(price.subtotal)),
                            PriceRow('GST (5%)', rupees(price.gstAmount)),
                            PriceRow('Delivery', price.deliveryCharge == 0 ? 'FREE' : rupees(price.deliveryCharge), valueColor: price.deliveryCharge == 0 ? AppColors.success : null),
                            if (price.couponDiscount > 0) PriceRow('Coupon', '- ${rupees(price.couponDiscount)}', valueColor: AppColors.success),
                            if (price.loyaltyDiscount > 0) PriceRow('Loyalty', '- ${rupees(price.loyaltyDiscount)}', valueColor: AppColors.success),
                            const Divider(height: 20),
                            PriceRow('Total', rupees(price.finalAmount), bold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 88),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, -2))],
                    ),
                    child: PrimaryButton(label: 'Proceed to Checkout · ${rupees(price.finalAmount)}', onPressed: () => context.push('/checkout')),
                  ),
                ),
              ],
            ),
    );
  }
}
