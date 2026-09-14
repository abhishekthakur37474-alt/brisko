import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../cart/view_cart_chip.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    const labels = ['Home', 'Menu', 'Reorder', 'Profile'];
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showNav = navigationShell.currentIndex == 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ViewCartChip(),
                if (showNav) ...[
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: List.generate(labels.length, (i) {
                          final selected = navigationShell.currentIndex == i;
                          final color = selected ? AppColors.primary : const Color(0xFFBBBBBB);
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _NavIcon(index: i, selected: selected, color: color),
                                    const SizedBox(height: 4),
                                    Text(
                                      labels[i],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected ? AppColors.white : const Color(0xFFBBBBBB),
                                        fontSize: 11,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final int index;
  final bool selected;
  final Color color;
  const _NavIcon({required this.index, required this.selected, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return HugeIcon(icon: HugeIcons.strokeRoundedHome03, color: color, size: 24);
      case 1:
        return HugeIcon(icon: HugeIcons.strokeRoundedPizza02, color: color, size: 24);
      case 2:
        return HugeIcon(icon: HugeIcons.strokeRoundedShoppingBag01, color: color, size: 24);
      default:
        return HugeIcon(icon: HugeIcons.strokeRoundedAccountSetting02, color: color, size: 24);
    }
  }
}
