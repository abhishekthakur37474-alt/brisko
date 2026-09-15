import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import 'store_status.dart';

/// Compact "outlet is closed" strip shown across the app so the user always
/// knows ordering is paused and when the kitchen opens again.
class StoreClosedBanner extends ConsumerWidget {
  final EdgeInsetsGeometry margin;
  final bool showHours;

  const StoreClosedBanner({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(16, 10, 16, 0),
    this.showHours = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(storeStatusProvider);
    if (!status.isClosed) return const SizedBox.shrink();

    final opensAt = status.nextOpenLabel ?? 'soon';
    final subtitle = showHours && status.hoursLabel.isNotEmpty
        ? 'Opens $opensAt · ${status.hoursLabel}'
        : 'Opens $opensAt';

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.access_time,
                color: AppColors.warning,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Brisko is closed',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.black),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'CLOSED',
                        style: TextStyle(
                          color: Color(0xFF9A6100),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
