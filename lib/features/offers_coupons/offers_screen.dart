import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
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
          ? const EmptyState(title: 'No offers', subtitle: 'Check back soon for coupons.', icon: Icons.local_offer_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: coupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = coupons[i];
                return AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.local_offer, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.code, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                            Text(c.description),
                            Text('Min order Rs ${c.minOrderValue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: c.code));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.code} copied')));
                        },
                        child: const Text('Copy'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
