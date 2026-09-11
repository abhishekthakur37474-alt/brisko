import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import 'coupon_controller.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(couponsProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: coupons.isEmpty
          ? const EmptyState(title: 'No offers', subtitle: 'Check back soon for coupons.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: coupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = coupons[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.code, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                      Text(c.description),
                      Text('Min order Rs ${c.minOrderValue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
