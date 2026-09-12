import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../cart/cart_controller.dart';

class ShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    const items = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.local_pizza_outlined, Icons.local_pizza, 'Menu'),
      (Icons.shopping_bag_outlined, Icons.shopping_bag, 'Cart'),
      (Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Material(
        color: AppColors.black,
        elevation: 12,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = navigationShell.currentIndex == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 3,
                            width: selected ? 22 : 0,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Badge(
                            isLabelVisible: i == 2 && count > 0,
                            backgroundColor: AppColors.primary,
                            label: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                            child: Icon(
                              selected ? items[i].$2 : items[i].$1,
                              color: selected ? AppColors.primary : const Color(0xFFBBBBBB),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? AppColors.primary : const Color(0xFFBBBBBB),
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
      ),
    );
  }
}
