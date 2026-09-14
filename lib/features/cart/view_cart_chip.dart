import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import 'cart_controller.dart';

class ViewCartChip extends ConsumerWidget {
  const ViewCartChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final visible = count > 0;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.4),
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: AppMotion.fast,
          child: Center(
            child: Material(
              color: AppColors.primary,
              elevation: 10,
              shadowColor: AppColors.primary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => context.push('/cart'),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: count > 0,
                        backgroundColor: AppColors.white,
                        textColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        label: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Text(
                            '$count',
                            key: ValueKey(count),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                        child: const HugeIcon(icon: HugeIcons.strokeRoundedShoppingBag01, color: AppColors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'View Cart',
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, color: AppColors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
