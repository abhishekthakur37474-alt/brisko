import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/firebase_service.dart';
import '../../core/utils/pricing.dart';
import '../auth/auth_controller.dart';
import '../location/location_controller.dart';
import '../loyalty/loyalty_config.dart';
import '../offers_coupons/coupon_model.dart';
import 'cart_item.dart';

final cartProvider = StreamProvider<List<CartItem>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return FirebaseService.instance.ref('users/${user.uid}/cart').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <CartItem>[];
    return val.entries
        .map((e) => CartItem.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .toList();
  });
});

final cartControllerProvider = Provider<CartController>((ref) => CartController(ref));

class CartController {
  CartController(this.ref);
  final Ref ref;
  final _uuid = const Uuid();

  String? get _uid => FirebaseService.instance.auth.currentUser?.uid;

  Future<void> add(CartItem item) async {
    final uid = _uid;
    if (uid == null) return;
    final id = item.id.isEmpty ? _uuid.v4() : item.id;
    await FirebaseService.instance.ref('users/$uid/cart/$id').set(item.toMap());
  }

  Future<String> addCustomized({
    required String productId,
    required String name,
    required String image,
    required bool isVeg,
    required double unitPrice,
    required String selectedSize,
    required String selectedCrust,
    required Map<String, double> toppings,
    required Map<String, double> addons,
    required int quantity,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Login required');
    final id = _uuid.v4();
    final item = CartItem(
      id: id,
      productId: productId,
      name: name,
      image: image,
      selectedSize: selectedSize,
      selectedCrust: selectedCrust,
      toppings: toppings,
      addons: addons,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: unitPrice * quantity,
      isVeg: isVeg,
    );
    await FirebaseService.instance.ref('users/$uid/cart/$id').set(item.toMap());
    return id;
  }

  Future<void> setQuantity(CartItem item, int qty) async {
    final uid = _uid;
    if (uid == null) return;
    if (qty <= 0) {
      await remove(item.id);
      return;
    }
    await FirebaseService.instance.ref('users/$uid/cart/${item.id}').update({
      'quantity': qty,
      'totalPrice': item.unitPrice * qty,
    });
  }

  Future<void> remove(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseService.instance.ref('users/$uid/cart/$id').remove();
  }

  Future<void> clear() async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseService.instance.ref('users/$uid/cart').remove();
  }

  Future<void> replaceAll(List<CartItem> items) async {
    final uid = _uid;
    if (uid == null) return;
    final map = <String, dynamic>{};
    for (final item in items) {
      final id = item.id.isEmpty ? _uuid.v4() : item.id;
      map[id] = item.toMap();
    }
    await FirebaseService.instance.ref('users/$uid/cart').set(map);
  }
}

final appliedCouponProvider = StateProvider<CouponModel?>((ref) => null);
final redeemLoyaltyProvider = StateProvider<bool>((ref) => false);

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider).valueOrNull ?? [];
  return items.fold<int>(0, (s, i) => s + i.quantity);
});

final priceBreakdownProvider = Provider<PriceBreakdown>((ref) {
  final items = ref.watch(cartProvider).valueOrNull ?? [];
  final coupon = ref.watch(appliedCouponProvider);
  final redeem = ref.watch(redeemLoyaltyProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  final loyalty = ref.watch(loyaltyConfigProvider).valueOrNull;
  final ordersCount = ref.watch(userOrderCountProvider).valueOrNull ?? 0;
  final orderMode = ref.watch(locationControllerProvider).orderMode;
  return Pricing.compute(
    items: items,
    coupon: coupon,
    loyalty: loyalty,
    availablePoints: user?.loyaltyPoints ?? 0,
    redeemLoyalty: redeem,
    isFirstOrder: ordersCount == 0,
    isPickup: orderMode != OrderMode.delivery,
  );
});

final loyaltyConfigProvider = StreamProvider((ref) {
  return FirebaseService.instance.ref('loyaltyConfig').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is Map) {
      return LoyaltyConfig.fromMap(Map<dynamic, dynamic>.from(val));
    }
    return const LoyaltyConfig();
  });
});

final userOrderCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  return FirebaseService.instance.ref('userOrders/${user.uid}').onValue.map((e) {
    final val = e.snapshot.value;
    if (val is Map) return val.length;
    return 0;
  });
});