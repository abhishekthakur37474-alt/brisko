import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pizza_loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../cart/cart_controller.dart';
import '../orders/orders_controller.dart';
import '../reviews/review_sheet.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  static const _steps = [
    ('placed', 'Placed', Icons.receipt_long_outlined),
    ('confirmed', 'Confirmed', Icons.check_circle_outline),
    ('preparing', 'Preparing', Icons.local_fire_department_outlined),
    ('ready', 'Ready', Icons.restaurant_outlined),
    ('out_for_delivery', 'On the way', Icons.delivery_dining_outlined),
    ('delivered', 'Delivered', Icons.home_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderByIdProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
      body: async.when(
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));
          final current = _steps.indexWhere((s) => s.$1 == order.orderStatus);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.id, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            '${rupees(order.finalAmount)} · ${order.paymentMethod.toUpperCase()} · ${order.paymentStatus}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: order.orderStatus),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: order.orderStatus == 'cancelled'
                    ? Row(
                        children: [
                          const Icon(Icons.cancel_outlined, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('This order was cancelled.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                          ),
                        ],
                      )
                    : Column(
                        children: List.generate(_steps.length, (i) {
                          final done = current >= i;
                          final active = current == i;
                          final last = i == _steps.length - 1;
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: done ? AppColors.success : AppColors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: active ? AppColors.primary : (done ? AppColors.success : AppColors.border), width: 2),
                                      ),
                                      child: Icon(
                                        done ? Icons.check : _steps[i].$3,
                                        size: 16,
                                        color: done ? AppColors.white : AppColors.muted,
                                      ),
                                    ),
                                    if (!last)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          color: done ? AppColors.success : AppColors.border,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: last ? 0 : 18, top: 4),
                                    child: Text(
                                      _steps[i].$2,
                                      style: TextStyle(
                                        fontWeight: active || done ? FontWeight.w700 : FontWeight.w400,
                                        color: done ? AppColors.text : AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
              ),
              const SizedBox(height: 16),
              Text('Delivering to', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AppCard(child: Text(order.address.fullAddress)),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    ...order.items.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [Expanded(child: Text('${e.name} x${e.quantity}')), Text(rupees(e.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700))]),
                        )),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Text('Invoice', style: TextStyle(fontWeight: FontWeight.w600))),
                        Text(order.invoiceUrl == null ? 'Generating...' : 'Ready', style: TextStyle(color: order.invoiceUrl == null ? AppColors.muted : AppColors.success)),
                        if (order.invoiceUrl != null)
                          IconButton(
                            tooltip: 'Open invoice',
                            onPressed: () => launchUrl(Uri.parse(order.invoiceUrl!)),
                            icon: const Icon(Icons.open_in_new),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.canCancel)
                OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Cancel order?'),
                        content: const Text('You can cancel only while the order is placed or confirmed.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cancel order')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      try {
                        await ref.read(ordersControllerProvider).cancel(order.id);
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Cancel order'),
                ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Reorder',
                onPressed: () async {
                  await ref.read(cartControllerProvider).replaceAll(order.items);
                  if (context.mounted) context.go('/cart');
                },
              ),
              if (order.orderStatus == 'delivered') ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    String? productId;
                    for (final item in order.items) {
                      if (item.productId.isNotEmpty) {
                        productId = item.productId;
                        break;
                      }
                    }
                    if (productId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No items available to review')),
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ReviewSheet(productId: productId!),
                    );
                  },
                  child: const Text('Rate & review'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const PizzaLoader(message: 'Tracking order...'),
        error: (e, _) => const Center(child: Text('Could not load this order')),
      ),
    );
  }
}
