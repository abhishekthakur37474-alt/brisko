import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/utils/pricing.dart';
import '../addresses/address_model.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_item.dart';
import '../location/location_controller.dart';
import '../location/store_status.dart';
import 'order_model.dart';

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return FirebaseService.instance.ref('userOrders/${user.uid}').onValue.asyncMap((event) async {
    final val = event.snapshot.value;
    if (val is! Map) return <OrderModel>[];
    final orders = <OrderModel>[];
    for (final id in val.keys) {
      final snap = await FirebaseService.instance.ref('orders/$id').get();
      if (snap.value is Map) {
        orders.add(OrderModel.fromMap(id.toString(), Map<dynamic, dynamic>.from(snap.value as Map)));
      }
    }
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  });
});

final orderByIdProvider = StreamProvider.family<OrderModel?, String>((ref, id) {
  return FirebaseService.instance.ref('orders/$id').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is Map) return OrderModel.fromMap(id, Map<dynamic, dynamic>.from(val));
    return null;
  });
});

final ordersControllerProvider = Provider((ref) => OrdersController(ref));

class OrdersController {
  OrdersController(this.ref);
  final Ref ref;
  final _payments = PaymentService();

  Future<String> placeOrder({
    required List<CartItem> items,
    required AddressModel address,
    required String outletId,
    required PriceBreakdown price,
    required String paymentMethod,
    required String notes,
    String? couponCode,
    OrderMode orderMode = OrderMode.delivery,
    String receiverName = '',
  }) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');
    if (items.isEmpty) throw Exception('Cart is empty');
    if (price.finalAmount <= 0) throw Exception('Invalid amount');
    final receiver = receiverName.trim().isNotEmpty ? receiverName.trim() : address.receiverName.trim();
    if (receiver.isEmpty) throw Exception('Receiver name is required');

    final store = ref.read(storeStatusProvider);
    if (store.isClosed) {
      throw Exception('Brisko is closed right now. Opens ${store.nextOpenLabel ?? 'soon'}.');
    }
    if (orderMode == OrderMode.delivery && !ref.read(locationControllerProvider).deliveryAvailable) {
      throw Exception('Delivery is not available for this location. Please choose Takeaway or Dine-In.');
    }

    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final pay = await _payments.gatewayFor(paymentMethod).pay(
          amount: price.finalAmount,
          orderId: orderId,
          currency: 'INR',
        );
    if (paymentMethod == 'online' && !pay.success) {
      throw Exception(pay.message ?? 'Online payment is coming soon. Choose Cash on Delivery.');
    }

    final order = OrderModel(
      id: orderId,
      userId: uid,
      outletId: outletId,
      items: items,
      address: address.copyWith(receiverName: receiver),
      subtotal: price.subtotal,
      gstAmount: price.gstAmount,
      deliveryCharge: price.deliveryCharge,
      couponCode: couponCode,
      couponDiscount: price.couponDiscount,
      loyaltyPointsUsed: price.loyaltyPointsUsed,
      loyaltyDiscount: price.loyaltyDiscount,
      finalAmount: price.finalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'cod' ? 'pending' : (pay.success ? 'paid' : 'pending'),
      orderStatus: 'placed',
      statusTimestamps: {'placed': now},
      orderNotes: notes,
      createdAt: now,
      updatedAt: now,
      receiverName: receiver,
      orderType: orderMode,
    );

    final updates = <String, dynamic>{
      'orders/$orderId': order.toMap(),
      'userOrders/$uid/$orderId': true,
      'outletOrders/$outletId/$orderId': true,
    };
    await FirebaseService.instance.ref('/').update(updates);
    await ref.read(cartControllerProvider).clear();
    ref.read(appliedCouponProvider.notifier).state = null;
    ref.read(redeemLoyaltyProvider.notifier).state = false;
    return orderId;
  }

  Future<void> cancel(String orderId) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseService.instance.ref('orders/$orderId').get();
    if (snap.value is! Map) return;
    final order = OrderModel.fromMap(orderId, Map<dynamic, dynamic>.from(snap.value as Map));
    if (!order.canCancel || order.userId != uid) {
      throw Exception('This order can no longer be cancelled.');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await FirebaseService.instance.ref('orders/$orderId').update({
      'orderStatus': 'cancelled',
      'updatedAt': now,
      'statusTimestamps/cancelled': now,
    });
  }
}