import '../cart/cart_item.dart';
import '../addresses/address_model.dart';

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
      paymentMethod: (map['paymentMethod'] ?? 'cod') as String,
      paymentStatus: (map['paymentStatus'] ?? 'pending') as String,
      orderStatus: (map['orderStatus'] ?? 'placed') as String,
      statusTimestamps: stamps,
      orderNotes: (map['orderNotes'] ?? '') as String,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
      invoiceUrl: map['invoiceUrl'] as String?,
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
    };
  }

  bool get canCancel => orderStatus == 'placed' || orderStatus == 'confirmed';
}
