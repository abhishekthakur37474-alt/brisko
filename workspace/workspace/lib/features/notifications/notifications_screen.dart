import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/empty_state.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: list.isEmpty
          ? const EmptyState(title: 'No notifications', subtitle: 'Order updates will appear here.')
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                return ListTile(
                  title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700)),
                  subtitle: Text('${n.body}\n${DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(n.createdAt))}'),
                  isThreeLine: true,
                  onTap: () {
                    NotificationsController().markRead(n.id);
                    if (n.orderId != null) context.push('/order/${n.orderId}');
                  },
                );
              },
            ),
    );
  }
}
