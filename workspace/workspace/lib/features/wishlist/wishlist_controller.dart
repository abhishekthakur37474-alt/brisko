import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import '../auth/auth_controller.dart';

final wishlistProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(<String>{});
  return FirebaseService.instance.ref('users/${user.uid}/wishlist').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <String>{};
    return val.keys.map((e) => e.toString()).toSet();
  });
});

final wishlistControllerProvider = Provider((ref) => WishlistController());

class WishlistController {
  Future<void> toggle(String productId) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseService.instance.ref('users/$uid/wishlist/$productId');
    final snap = await ref.get();
    if (snap.exists) {
      await ref.remove();
    } else {
      await ref.set(true);
    }
  }
}
