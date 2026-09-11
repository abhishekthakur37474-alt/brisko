class CartItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final String selectedSize;
  final String selectedCrust;
  final Map<String, double> toppings;
  final Map<String, double> addons;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isVeg;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.selectedSize,
    required this.selectedCrust,
    required this.toppings,
    required this.addons,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.isVeg = true,
  });

  factory CartItem.fromMap(String id, Map<dynamic, dynamic> map) {
    Map<String, double> parseMap(dynamic node) {
      if (node is! Map) return {};
      return node.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    return CartItem(
      id: id,
      productId: (map['productId'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      image: (map['image'] ?? '') as String,
      selectedSize: (map['selectedSize'] ?? '') as String,
      selectedCrust: (map['selectedCrust'] ?? '') as String,
      toppings: parseMap(map['toppings']),
      addons: parseMap(map['addons']),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      isVeg: map['isVeg'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'image': image,
        'selectedSize': selectedSize,
        'selectedCrust': selectedCrust,
        'toppings': toppings,
        'addons': addons,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'isVeg': isVeg,
      };

  CartItem copyWith({int? quantity, double? totalPrice}) {
    final qty = quantity ?? this.quantity;
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      image: image,
      selectedSize: selectedSize,
      selectedCrust: selectedCrust,
      toppings: toppings,
      addons: addons,
      quantity: qty,
      unitPrice: unitPrice,
      totalPrice: totalPrice ?? unitPrice * qty,
      isVeg: isVeg,
    );
  }
}
