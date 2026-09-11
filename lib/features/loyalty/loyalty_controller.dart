import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import '../auth/auth_controller.dart';
import 'loyalty_config.dart';

final loyaltyHistoryProvider = StreamProvider<List<LoyaltyEntry>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return FirebaseService.instance.ref('users/${user.uid}/loyaltyHistory').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <LoyaltyEntry>[];
    return val.entries
        .map((e) => LoyaltyEntry.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });
});
