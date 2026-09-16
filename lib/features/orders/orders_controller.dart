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
    String receiverPhone = '',
    String upiTxnId = '',
    String upiResponseCode = '',
    String upiPayerVpa = '',
    String upiTransactionRef = '',
    String paymentProofUrl = '',
  }) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');
    if (items.isEmpty) throw Exception('Cart is empty');
    if (price.finalAmount <= 0) throw Exception('Invalid amount');
    final receiver = receiverName.trim().isNotEmpty ? receiverName.trim() : address.receiverName.trim();
    if (receiver.isEmpty) throw Exception('Receiver name is required');
    final receiverContact = receiverPhone.trim().isNotEmpty ? receiverPhone.trim() : address.receiverPhone.trim();
    if (receiverContact.isEmpty) throw Exception('Receiver phone is required');

    final store = ref.read(storeStatusProvider);
    if (store.isClosed) {
      throw Exception('Brisko is closed right now. Opens ${store.nextOpenLabel ?? 'soon'}.');
    }
    if (orderMode == OrderMode.delivery && !ref.read(locationControllerProvider).deliveryAvailable) {
      throw Exception('Delivery is not available for this location. Please choose Takeaway or Dine-In.');
    }

    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final isUpi = paymentMethod == 'upi_intent';

    // Only the 'online' mock gateway is routed through PaymentService. UPI Intent
    // is driven by the UPI app in checkout and confirmed server-side, so it never
    // needs a client gateway (the old always-success stub was removed).
    if (paymentMethod == 'online') {
      final pay = await _payments.gatewayFor('online').pay(
            amount: price.finalAmount,
            orderId: orderId,
            currency: 'INR',
          );
      if (!pay.success) {
        throw Exception(pay.message ?? 'Online payment is coming soon. Choose Cash on Delivery.');
      }
    }

    final order = OrderModel(
      id: orderId,
      userId: uid,
      outletId: outletId,
      items: items,
      address: address.copyWith(receiverName: receiver, receiverPhone: receiverContact),
      subtotal: price.subtotal,
      gstAmount: price.gstAmount,
      deliveryCharge: price.deliveryCharge,
      couponCode: couponCode,
      couponDiscount: price.couponDiscount,
      loyaltyPointsUsed: price.loyaltyPointsUsed,
      loyaltyDiscount: price.loyaltyDiscount,
      finalAmount: price.finalAmount,
      paymentMethod: paymentMethod,
      // UpI Intent orders are always created pending. The client can never mark
      // an online order paid; the backend verifies and flips the status.
      paymentStatus: 'pending',
      orderStatus: 'placed',
      statusTimestamps: {'placed': now},
      orderNotes: notes,
      createdAt: now,
      updatedAt: now,
      receiverName: receiver,
      receiverPhone: receiverContact,
      orderType: orderMode,
      upiTxnId: isUpi ? upiTxnId : '',
      upiResponseCode: isUpi ? upiResponseCode : '',
      upiPayerVpa: isUpi ? upiPayerVpa : '',
      upiTransactionRef: isUpi ? upiTransactionRef : '',
      paymentProofUrl: isUpi ? paymentProofUrl : '',
      paymentVerification: isUpi ? 'pending' : 'not_required',
    );

    final updates = <String, dynamic>{
      'orders/$orderId': order.toMap(),
      'userOrders/$uid/$orderId': true,
      'outletOrders/$outletId/$orderId': true,
    };
    await FirebaseService.instance.ref('/').update(updates);
    await ref.read(authControllerProvider).adoptNameIfBlank(receiver);
    await ref.read(cartControllerProvider).clear();
    ref.read(appliedCouponProvider.notifier).state = null;
    ref.read(redeemLoyaltyProvider.notifier).state = false;

    // Manual UPI/QR payments are confirmed by an admin from the Orders page.
    // The order stays pending (and the customer sees a waiting message) until
    // the admin approves or rejects the uploaded payment proof.
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
    final patch = <String, dynamic>{
      'orderStatus': 'cancelled',
      'updatedAt': now,
      'statusTimestamps/cancelled': now,
    };
    // A paid UPI order cannot be silently kept: flag it so the admin refunds the
    // customer. The client can only raise the request; only the backend/admin
    // may mark it 'refunded'.
    final isPaidUpi = order.paymentMethod.toLowerCase() == 'upi_intent' &&
        order.paymentStatus.toLowerCase() == 'paid';
    if (isPaidUpi) {
      patch['refundStatus'] = 'requested';
      patch['refundRequestedAt'] = now;
    }
    await FirebaseService.instance.ref('orders/$orderId').update(patch);
  }
}