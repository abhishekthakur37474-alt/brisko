import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/price_row.dart';
import '../../core/widgets/primary_button.dart';
import '../addresses/address_controller.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../location/location_controller.dart';
import '../orders/orders_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _method = 'cod';
  final _notes = TextEditingController();
  bool _loading = false;
  bool _notesOpen = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    final items = ref.watch(cartProvider).valueOrNull ?? [];
    final price = ref.watch(priceBreakdownProvider);
    final coupon = ref.watch(appliedCouponProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final loyalty = ref.watch(loyaltyConfigProvider).valueOrNull;
    final redeem = ref.watch(redeemLoyaltyProvider);
    final addresses = ref.watch(addressesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Delivery address', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(20),
            selected: loc.address != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.address?.fullAddress ?? 'No address selected', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (loc.outlet != null) Text('Outlet: ${loc.outlet!.name}', style: const TextStyle(color: AppColors.muted)),
                TextButton(onPressed: () => context.push('/addresses'), child: const Text('Change address')),
                if (addresses.isNotEmpty)
                  ...addresses.map((a) => RadioListTile<String>(
                        value: a.id,
                        groupValue: loc.address?.id,
                        title: Text(a.label),
                        subtitle: Text(a.fullAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (_) {
                          final outlets = ref.read(outletsProvider).valueOrNull ?? [];
                          ref.read(locationControllerProvider.notifier).setFromSaved(a, outlets);
                        },
                      )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Loyalty points', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: redeem,
              title: Text('Redeem points (${user?.loyaltyPoints ?? 0} available)'),
              subtitle: Text(loyalty == null ? '' : 'Min ${loyalty.minPointsToRedeem} pts · 1 pt = ${rupees(loyalty.redemptionValuePerPoint)}'),
              onChanged: (user?.loyaltyPoints ?? 0) >= (loyalty?.minPointsToRedeem ?? 50)
                  ? (v) => ref.read(redeemLoyaltyProvider.notifier).state = v
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Text('Payment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            selected: _method == 'cod',
            child: RadioListTile<String>(
              value: 'cod',
              groupValue: _method,
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when your pizza arrives'),
              onChanged: (v) => setState(() => _method = v!),
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            selected: _method == 'online',
            child: RadioListTile<String>(
              value: 'online',
              groupValue: _method,
              title: const Text('Online payment'),
              subtitle: const Text('Coming soon'),
              onChanged: (v) => setState(() => _method = v!),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _notesOpen = !_notesOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.notes_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_notesOpen ? 'Order notes' : 'Add order notes (optional)', style: const TextStyle(fontWeight: FontWeight.w600))),
                  Icon(_notesOpen ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: AppMotion.fast,
            crossFadeState: _notesOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Order notes')),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                PriceRow('Subtotal', rupees(price.subtotal)),
                PriceRow('GST', rupees(price.gstAmount)),
                PriceRow('Delivery', price.deliveryCharge == 0 ? 'FREE' : rupees(price.deliveryCharge), valueColor: price.deliveryCharge == 0 ? AppColors.success : null),
                if (price.couponDiscount > 0) PriceRow('Coupon', '- ${rupees(price.couponDiscount)}', valueColor: AppColors.success),
                if (price.loyaltyDiscount > 0) PriceRow('Loyalty', '- ${rupees(price.loyaltyDiscount)}', valueColor: AppColors.success),
                const Divider(height: 20),
                PriceRow('To pay', rupees(price.finalAmount), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 88),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: AppColors.softShadow,
          ),
          child: PrimaryButton(
            label: 'Place Order · ${rupees(price.finalAmount)}',
            loading: _loading,
            onPressed: loc.outlet == null || loc.address == null || items.isEmpty
                ? null
                : () async {
                    if (_method == 'online') {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online payment coming soon. Choose Cash on Delivery.')));
                      return;
                    }
                    setState(() => _loading = true);
                    try {
                      final id = await ref.read(ordersControllerProvider).placeOrder(
                            items: items,
                            address: loc.address!,
                            outletId: loc.outlet!.id,
                            price: price,
                            paymentMethod: _method,
                            notes: _notes.text,
                            couponCode: coupon?.code,
                          );
                      if (context.mounted) context.go('/order-confirm/$id');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
          ),
        ),
      ),
    );
  }
}