import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pizza_loader.dart';
import '../cart/cart_controller.dart';
import '../orders/orders_controller.dart';
import '../reviews/review_sheet.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderByIdProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
      body: async.when(
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));
          final steps = ['placed', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered'];
          final current = steps.indexOf(order.orderStatus);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(order.id, style: Theme.of(context).textTheme.titleLarge),
              Text('${rupees(order.finalAmount)} · ${order.paymentMethod.toUpperCase()} · ${order.paymentStatus}'),
              const SizedBox(height: 16),
              if (order.orderStatus == 'cancelled')
                const Text('This order was cancelled.', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))
              else
                ...List.generate(steps.length, (i) {
                  final done = current >= i;
                  return ListTile(
                    leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? AppColors.success : AppColors.muted),
                    title: Text(steps[i].replaceAll('_', ' '), style: TextStyle(fontWeight: done ? FontWeight.w700 : FontWeight.w400)),
                  );
                }),
              const SizedBox(height: 12),
              Text('Delivering to', style: Theme.of(context).textTheme.titleMedium),
              Text(order.address.fullAddress),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              ...order.items.map((e) => ListTile(contentPadding: EdgeInsets.zero, title: Text('${e.name} x${e.quantity}'), trailing: Text(rupees(e.totalPrice)))),
              const Divider(),
              ListTile(contentPadding: EdgeInsets.zero, title: const Text('Invoice'), subtitle: Text(order.invoiceUrl == null ? 'Generating...' : 'Ready'), trailing: order.invoiceUrl == null ? null : IconButton(onPressed: () => launchUrl(Uri.parse(order.invoiceUrl!)), icon: const Icon(Icons.open_in_new))),
              const SizedBox(height: 12),
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
              ElevatedButton(
                onPressed: () async {
                  await ref.read(cartControllerProvider).replaceAll(order.items);
                  if (context.mounted) context.go('/cart');
                },
                child: const Text('Reorder'),
              ),
              if (order.orderStatus == 'delivered') ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ReviewSheet(productId: order.items.first.productId),
                  ),
                  child: const Text('Rate & review'),
                ),
              ],
            ],
          );
        },
        loading: () => const PizzaLoader(message: 'Tracking order...'),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
