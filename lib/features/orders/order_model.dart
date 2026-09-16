import '../cart/cart_item.dart';
import '../addresses/address_model.dart';
import '../location/location_controller.dart';

const orderStatuses = [
  'placed',
  'confirmed',
  'preparing',
  'ready',
  'out_for_delivery',
  'delivered',
  'cancelled',
];

class OrderModel {
  final String id;
  final String userId;
  final String outletId;
  final List<CartItem> items;
  final AddressModel address;
  final double subtotal;
  final double gstAmount;
  final double deliveryCharge;
  final String? couponCode;
  final double couponDiscount;
  final int loyaltyPointsUsed;
  final double loyaltyDiscount;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final Map<String, int> statusTimestamps;
  final String orderNotes;
  final int createdAt;
  final int updatedAt;
  final String? invoiceUrl;
  // Name of the person receiving/collecting the order.
  final String receiverName;
  // Contact number of the person receiving/collecting the order.
  final String receiverPhone;
  // How the customer gets the order: delivery / takeaway / dineIn.
  final OrderMode orderType;
  // UPI Intent transaction details. Reported by the customer's UPI app and
  // recorded so the payment can be reconciled against the bank statement.
  final String upiTxnId;
  final String upiResponseCode;
  final String upiPayerVpa;
  final String upiTransactionRef;
  // Server-controlled payment review. The client only ever writes 'pending';
  // only the backend/admin (Admin SDK, bypasses rules) may set 'verified'.
  final String paymentVerification;
  final int? paymentVerifiedAt;
  // Manual refund tracking for UPI payments. `refundStatus` is 'requested'
  // when the customer cancels a paid UPI order and 'refunded' once an admin
  // has processed it.
  final String refundStatus;
  final int? refundRequestedAt;
  final int? refundedAt;
  final String refundRef;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.outletId,
    required this.items,
    required this.address,
    required this.subtotal,
    required this.gstAmount,
    required this.deliveryCharge,
    this.couponCode,
    required this.couponDiscount,
    required this.loyaltyPointsUsed,
    required this.loyaltyDiscount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.statusTimestamps,
    required this.orderNotes,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceUrl,
    this.receiverName = '',
    this.receiverPhone = '',
    this.orderType = OrderMode.delivery,
    this.upiTxnId = '',
    this.upiResponseCode = '',
    this.upiPayerVpa = '',
    this.upiTransactionRef = '',
    this.paymentVerification = 'not_required',
    this.paymentVerifiedAt,
    this.refundStatus = '',
    this.refundRequestedAt,
    this.refundedAt,
    this.refundRef = '',
  });

  factory OrderModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final itemsNode = map['items'];
    final items = <CartItem>[];
    if (itemsNode is Map) {
      final keys = itemsNode.keys.toList()..sort((a, b) => a.toString().compareTo(b.toString()));
      for (final k in keys) {
        final v = itemsNode[k];
        if (v is Map) {
          items.add(CartItem.fromMap(k.toString(), Map<dynamic, dynamic>.from(v)));
        }
      }
    } else if (itemsNode is List) {
      for (var i = 0; i < itemsNode.length; i++) {
        final v = itemsNode[i];
        if (v is Map) {
          items.add(CartItem.fromMap('$i', Map<dynamic, dynamic>.from(v)));
        }
      }
    }
    final addr = map['addressSnapshot'] is Map
        ? AddressModel.fromMap('snap', Map<dynamic, dynamic>.from(map['addressSnapshot'] as Map))
        : const AddressModel(id: '', label: '', fullAddress: '', lat: 0, lng: 0);
    final stamps = <String, int>{};
    if (map['statusTimestamps'] is Map) {
      (map['statusTimestamps'] as Map).forEach((k, v) {
        stamps[k.toString()] = (v as num).toInt();
      });
    }
    final orderStatus = _normalizeStatus((map['orderStatus'] ?? 'placed').toString());
    final paymentMethod = (map['paymentMethod'] ?? 'cod') as String;
    final rawPaymentStatus = (map['paymentStatus'] ?? 'pending').toString().toLowerCase();
    // COD is collected on delivery. Older delivered orders may still carry a
    // stale "pending" value in the database, so derive the correct status here.
    final paymentStatus = (orderStatus == 'delivered' &&
            paymentMethod.toLowerCase() == 'cod' &&
            rawPaymentStatus != 'paid')
        ? 'paid'
        : rawPaymentStatus;
    return OrderModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      outletId: (map['outletId'] ?? '') as String,
      items: items,
      address: addr,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      gstAmount: (map['gstAmount'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      couponCode: map['couponCode'] as String?,
      couponDiscount: (map['couponDiscount'] as num?)?.toDouble() ?? 0,
      loyaltyPointsUsed: (map['loyaltyPointsUsed'] as num?)?.toInt() ?? 0,
      loyaltyDiscount: (map['loyaltyDiscount'] as num?)?.toDouble() ?? 0,
      finalAmount: (map['finalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      orderStatus: orderStatus,
      statusTimestamps: stamps,
      orderNotes: (map['orderNotes'] ?? '') as String,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
      invoiceUrl: map['invoiceUrl'] as String?,
      receiverName: (map['receiverName'] as String?)?.trim().isNotEmpty == true
          ? map['receiverName'] as String
          : addr.receiverName,
      receiverPhone: (map['receiverPhone'] as String?)?.trim().isNotEmpty == true
          ? map['receiverPhone'] as String
          : addr.receiverPhone,
      orderType: _parseOrderType(map['orderType']),
      upiTxnId: (map['upiTxnId'] ?? '') as String,
      upiResponseCode: (map['upiResponseCode'] ?? '') as String,
      upiPayerVpa: (map['upiPayerVpa'] ?? '') as String,
      upiTransactionRef: (map['upiTransactionRef'] ?? '') as String,
      paymentVerification: ((map['paymentVerification'] ?? '') as String).isNotEmpty
          ? map['paymentVerification'] as String
          : (paymentMethod.toLowerCase() == 'upi_intent' ? 'pending' : 'not_required'),
      paymentVerifiedAt: (map['paymentVerifiedAt'] as num?)?.toInt(),
      refundStatus: (map['refundStatus'] ?? '') as String,
      refundRequestedAt: (map['refundRequestedAt'] as num?)?.toInt(),
      refundedAt: (map['refundedAt'] as num?)?.toInt(),
      refundRef: (map['refundRef'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    final itemsMap = <String, dynamic>{};
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final key = item.id.isNotEmpty ? item.id : '$i';
      itemsMap[key] = item.toMap();
    }
    return {
      'userId': userId,
      'outletId': outletId,
      'items': itemsMap,
      'addressSnapshot': address.toMap(),
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'deliveryCharge': deliveryCharge,
      'couponCode': couponCode,
      'couponDiscount': couponDiscount,
      'loyaltyPointsUsed': loyaltyPointsUsed,
      'loyaltyDiscount': loyaltyDiscount,
      'finalAmount': finalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'statusTimestamps': statusTimestamps,
      'orderNotes': orderNotes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'invoiceUrl': invoiceUrl,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'orderType': orderType.name,
      'upiTxnId': upiTxnId,
      'upiResponseCode': upiResponseCode,
      'upiPayerVpa': upiPayerVpa,
      'upiTransactionRef': upiTransactionRef,
      'paymentVerification': paymentVerification,
      'paymentVerifiedAt': paymentVerifiedAt,
      'refundStatus': refundStatus,
      'refundRequestedAt': refundRequestedAt,
      'refundedAt': refundedAt,
      'refundRef': refundRef,
    };
  }

  bool get canCancel => orderStatus == 'placed' || orderStatus == 'confirmed';

  /// A refund the customer is owed but that has not been processed yet.
  bool get isRefundPending =>
      refundStatus.toLowerCase() == 'requested' &&
      paymentStatus.toLowerCase() != 'refunded';

  bool get isRefunded => paymentStatus.toLowerCase() == 'refunded';

  /// True when an online payment is still awaiting server/admin confirmation.
  bool get isPaymentUnderReview =>
      paymentMethod.toLowerCase() == 'upi_intent' &&
      paymentStatus.toLowerCase() != 'paid' &&
      paymentStatus.toLowerCase() != 'refunded';

  static OrderMode _parseOrderType(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    for (final mode in OrderMode.values) {
      if (mode.name == s) return mode;
    }
    return OrderMode.delivery;
  }

  static String _normalizeStatus(String raw) {
    final s = raw.toLowerCase().trim().replaceAll(' ', '_');
    if (s == 'on_the_way' || s == 'ontheway' || s == 'on-the-way') return 'out_for_delivery';
    if (orderStatuses.contains(s)) return s;
    return 'placed';
  }
}