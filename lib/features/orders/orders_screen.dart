import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pizza_loader.dart';
import '../../core/widgets/status_chip.dart';
import 'orders_controller.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: async.when(
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyState(
              title: 'No orders yet',
              subtitle: 'Your pizza history will show up here.',
              actionLabel: 'Order now',
              onAction: () => context.go('/menu'),
              icon: Icons.receipt_long_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = orders[i];
              return AppCard(
                onTap: () => context.push('/order/${o.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.local_pizza, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.items.isNotEmpty ? o.items.first.name : o.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(o.createdAt)),
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          StatusChip(status: o.orderStatus),
                        ],
                      ),
                    ),
                    Text(rupees(o.finalAmount), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const PizzaLoader(message: 'Loading orders...'),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
