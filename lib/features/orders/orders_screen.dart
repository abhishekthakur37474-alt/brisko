import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pizza_loader.dart';
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
            return EmptyState(title: 'No orders yet', subtitle: 'Your pizza history will show up here.', actionLabel: 'Order now', onAction: () => context.go('/menu'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = orders[i];
              return ListTile(
                onTap: () => context.push('/order/${o.id}'),
                tileColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(o.id),
                subtitle: Text('${o.orderStatus.replaceAll('_', ' ')} · ${DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(o.createdAt))}'),
                trailing: Text(rupees(o.finalAmount), style: const TextStyle(fontWeight: FontWeight.w700)),
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
