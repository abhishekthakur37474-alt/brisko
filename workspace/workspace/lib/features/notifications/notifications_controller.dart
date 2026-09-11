import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import '../auth/auth_controller.dart';
import 'notification_model.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return FirebaseService.instance.ref('users/${user.uid}/notifications').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <NotificationModel>[];
    return val.entries
        .map((e) => NotificationModel.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });
});

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? [];
  return list.where((n) => !n.isRead).length;
});

class NotificationsController {
  Future<void> markRead(String id) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) return;
    await FirebaseService.instance.ref('users/$uid/notifications/$id/isRead').set(true);
  }
}
