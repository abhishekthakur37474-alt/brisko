import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/empty_state.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider).valueOrNull ?? [];
    final unread = list.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          BriskoTopBar(
            title: 'Notifications',
            subtitle: unread == 0 ? 'You are all caught up' : 'Latest updates',
            badgeCount: unread == 0 ? null : unread,
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(title: 'No notifications', subtitle: 'Order updates will appear here.', icon: Icons.notifications_none)
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = list[i];
                return AppCard(
                  color: n.isRead ? AppColors.white : AppColors.cream,
                  onTap: () {
                    NotificationsController().markRead(n.id);
                    if (n.orderId != null) context.push('/order/${n.orderId}');
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedNotification01, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(n.body, style: const TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(n.createdAt)),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
