import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brisko_top_bar.dart';
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
    final points = user?.loyaltyPoints ?? 0;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const BriskoTopBar(
            title: 'Loyalty',
            subtitle: 'Earn on every order',
          ),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current balance', style: TextStyle(color: Color(0xFFCCCCCC))),
                const SizedBox(height: 6),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: points),
                  duration: const Duration(milliseconds: 700),
                  curve: AppMotion.easeOut,
                  builder: (context, value, _) {
                    return Text('$value pts', style: const TextStyle(color: AppColors.white, fontSize: 36, fontWeight: FontWeight.w800));
                  },
                ),
                const SizedBox(height: 8),
                Text('Earned $earned · Redeemed $redeemed', style: const TextStyle(color: Color(0xFFDDDDDD))),
                if (config != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Earn ${config.pointsPerRupeeSpent} pts per rupee. Min redeem ${config.minPointsToRedeem}.',
                      style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const EmptyState(title: 'No points yet', subtitle: 'Points are credited when an order is delivered.', icon: Icons.card_giftcard)
          else
            ...history.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: e.pointsEarned > 0 ? AppColors.successSoft : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            e.pointsEarned > 0 ? Icons.add : Icons.remove,
                            color: e.pointsEarned > 0 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.pointsEarned > 0 ? '+${e.pointsEarned} earned' : '-${e.pointsRedeemed} redeemed', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.createdAt)), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${e.balanceAfter}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                )),
        ],
            ),
          ),
        ],
      ),
    );
  }
}
