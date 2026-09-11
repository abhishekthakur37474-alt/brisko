import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
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
          ? EmptyState(title: 'Cart is empty', subtitle: 'Add a pizza and we will fire up the oven.', actionLabel: 'Browse menu', onAction: () => context.go('/menu'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item.image.isEmpty
                                ? const SizedBox(width: 64, height: 64, child: ColoredBox(color: AppColors.grey))
                                : CachedNetworkImage(imageUrl: item.image, width: 64, height: 64, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                                if (item.selectedSize.isNotEmpty || item.selectedCrust.isNotEmpty)
                                  Text([item.selectedSize, item.selectedCrust].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                Text(rupees(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(onPressed: () => ref.read(cartControllerProvider).setQuantity(item, item.quantity - 1), icon: const Icon(Icons.remove_circle_outline)),
                                  Text('${item.quantity}'),
                                  IconButton(onPressed: () => ref.read(cartControllerProvider).setQuantity(item, item.quantity + 1), icon: const Icon(Icons.add_circle_outline)),
                                ],
                              ),
                              TextButton(onPressed: () => ref.read(cartControllerProvider).remove(item.id), child: const Text('Remove')),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: _coupon,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Coupon code',
                    suffixIcon: TextButton(
                      onPressed: () async {
                        try {
                          final c = await ref.read(applyCouponProvider).apply(_coupon.text);
                          setState(() => _couponMsg = c.description);
                        } catch (e) {
                          setState(() => _couponMsg = e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ),
                if (coupon != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Applied: ${coupon.code}', style: const TextStyle(color: AppColors.success))),
                if (_couponMsg != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_couponMsg!)),
                const SizedBox(height: 16),
                _Line('Subtotal', rupees(price.subtotal)),
                _Line('GST (5%)', rupees(price.gstAmount)),
                _Line('Delivery', price.deliveryCharge == 0 ? 'FREE' : rupees(price.deliveryCharge)),
                if (price.couponDiscount > 0) _Line('Coupon', '- ${rupees(price.couponDiscount)}'),
                if (price.loyaltyDiscount > 0) _Line('Loyalty', '- ${rupees(price.loyaltyDiscount)}'),
                const Divider(),
                _Line('Total', rupees(price.finalAmount), bold: true),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Proceed to Checkout', onPressed: () => context.push('/checkout')),
              ],
            ),
    );
  }
}

class _Line extends StatelessWidget {
  final String l;
  final String r;
  final bool bold;
  const _Line(this.l, this.r, {this.bold = false});
  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(l, style: style)), Text(r, style: style)]),
    );
  }
}
