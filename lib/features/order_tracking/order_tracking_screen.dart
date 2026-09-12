import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/glass_sheet.dart';
import '../../core/widgets/pizza_loader.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../cart/cart_controller.dart';
import '../orders/order_model.dart';
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
          final raw = order.orderStatus;
          final current = _steps.indexWhere((s) => s.$1 == raw);
          final safeIndex = current == -1 ? 0 : current;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Hero(
                      tag: 'order-icon-${order.id}',
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.local_pizza, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                    : _StatusStepper(steps: _steps, current: safeIndex),
              ),
              const SizedBox(height: 24),
              Text('Delivering to', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AppCard(child: Text(order.address.fullAddress)),
              const SizedBox(height: 24),
              _ItemsSummary(order: order),
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
                    showGlassSheet(
                      context: context,
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

class _ItemsSummary extends StatefulWidget {
  final OrderModel order;
  const _ItemsSummary({required this.order});

  @override
  State<_ItemsSummary> createState() => _ItemsSummaryState();
}

class _ItemsSummaryState extends State<_ItemsSummary> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final count = order.items.fold<int>(0, (s, e) => s + e.quantity);
    return AppCard(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$count items · ${rupees(order.finalAmount)} — tap to view',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(_open ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: AppMotion.fast,
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final List<(String, String, IconData)> steps;
  final int current;
  const _StatusStepper({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final done = current >= i;
        final active = current == i;
        final last = i == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: done ? AppColors.success : AppColors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: active ? AppColors.primary : (done ? AppColors.success : AppColors.border), width: 2),
                  ),
                  child: Icon(
                    done ? Icons.check : steps[i].$3,
                    size: 16,
                    color: done ? AppColors.white : AppColors.muted,
                  ),
                ),
                if (!last)
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: done && current > i ? AppColors.success : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 8, top: 6),
                child: Text(
                  steps[i].$2,
                  style: TextStyle(
                    fontWeight: active || done ? FontWeight.w700 : FontWeight.w400,
                    color: done ? AppColors.text : AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
