import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import '../cart/cart_controller.dart';
import 'coupon_model.dart';

final couponsProvider = StreamProvider<List<CouponModel>>((ref) {
  return FirebaseService.instance.ref('coupons').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <CouponModel>[];
    return val.entries
        .map((e) => CouponModel.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .where((c) => c.isValidNow)
        .toList();
  });
});

class CouponController {
  static Future<CouponModel> validate(String code, {required bool isFirstOrder, required int usageCount}) async {
    final snap = await FirebaseService.instance.ref('coupons/${code.trim().toUpperCase()}').get();
    if (snap.value is! Map) throw Exception('Coupon not found');
    final coupon = CouponModel.fromMap(code.trim().toUpperCase(), Map<dynamic, dynamic>.from(snap.value as Map));
    if (!coupon.isValidNow) throw Exception('Coupon expired or inactive');
    if (coupon.isFirstOrderOnly && !isFirstOrder) throw Exception('This coupon is for first orders only');
    if (usageCount >= coupon.usageLimitPerUser) throw Exception('Usage limit reached for this coupon');
    return coupon;
  }
}

final applyCouponProvider = Provider((ref) => ApplyCoupon(ref));

class ApplyCoupon {
  ApplyCoupon(this.ref);
  final Ref ref;

  Future<CouponModel> apply(String code) async {
    final count = ref.read(userOrderCountProvider).valueOrNull ?? 0;
    final coupon = await CouponController.validate(code, isFirstOrder: count == 0, usageCount: 0);
    final items = ref.read(cartProvider).valueOrNull ?? [];
    final subtotal = items.fold<double>(0, (s, i) => s + i.totalPrice);
    if (subtotal < coupon.minOrderValue) {
      throw Exception('Min order value is Rs ${coupon.minOrderValue.toStringAsFixed(0)}');
    }
    ref.read(appliedCouponProvider.notifier).state = coupon;
    return coupon;
  }
}
