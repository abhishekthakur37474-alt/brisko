import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import 'loyalty_controller.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final history = ref.watch(loyaltyHistoryProvider).valueOrNull ?? [];
    final config = ref.watch(loyaltyConfigProvider).valueOrNull;
    final earned = history.fold<int>(0, (s, e) => s + e.pointsEarned);
    final redeemed = history.fold<int>(0, (s, e) => s + e.pointsRedeemed);
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current balance', style: TextStyle(color: AppColors.white)),
                Text('${user?.loyaltyPoints ?? 0} pts', style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                Text('Earned $earned · Redeemed $redeemed', style: const TextStyle(color: Color(0xFFDDDDDD))),
                if (config != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Earn ${config.pointsPerRupeeSpent} pts per rupee. Min redeem ${config.minPointsToRedeem}.',
                      style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('History', style: Theme.of(context).textTheme.titleLarge),
          if (history.isEmpty)
            const EmptyState(title: 'No points yet', subtitle: 'Points are credited when an order is delivered.')
          else
            ...history.map((e) => ListTile(
                  title: Text(e.pointsEarned > 0 ? '+${e.pointsEarned} earned' : '-${e.pointsRedeemed} redeemed'),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.createdAt))),
                  trailing: Text('${e.balanceAfter}'),
                )),
        ],
      ),
    );
  }
}
