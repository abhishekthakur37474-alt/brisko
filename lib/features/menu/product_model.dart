class CustomOption {
  final String id;
  final String name;
  final double price;

  const CustomOption({required this.id, required this.name, required this.price});

  factory CustomOption.fromMap(String id, Map<dynamic, dynamic> map) {
    return CustomOption(
      id: id,
      name: (map['name'] ?? id) as String,
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final List<String> images;
  final double basePrice;
  final bool isVeg;
  final bool isBestSeller;
  final bool isFeatured;
  final bool isActive;
  final List<String> outletIds;
  final List<CustomOption> sizes;
  final List<CustomOption> crusts;
  final List<CustomOption> toppings;
  final List<CustomOption> addons;
  final double avgRating;
  final int reviewCount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.images,
    required this.basePrice,
    required this.isVeg,
    this.isBestSeller = false,
    this.isFeatured = false,
    this.isActive = true,
    this.outletIds = const [],
    this.sizes = const [],
    this.crusts = const [],
    this.toppings = const [],
    this.addons = const [],
    this.avgRating = 0,
    this.reviewCount = 0,
  });

  String get image => images.isNotEmpty ? images.first : '';

  bool get hasCustomizations =>
      sizes.isNotEmpty || crusts.isNotEmpty || toppings.isNotEmpty || addons.isNotEmpty;

  factory ProductModel.fromMap(String id, Map<dynamic, dynamic> map) {
    List<CustomOption> parseOptions(dynamic node) {
      if (node is! Map) return [];
      return node.entries
          .map((e) => CustomOption.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
          .toList();
    }

    final imagesMap = map['images'];
    final images = <String>[];
    if (imagesMap is Map) {
      final keys = imagesMap.keys.toList()..sort((a, b) => a.toString().compareTo(b.toString()));
      for (final k in keys) {
        images.add(imagesMap[k].toString());
      }
    } else if (imagesMap is List) {
      images.addAll(imagesMap.map((e) => e.toString()));
    }

    final outletIdsMap = map['outletIds'];
    final outletIds = <String>[];
    if (outletIdsMap is Map) {
      outletIds.addAll(outletIdsMap.keys.map((e) => e.toString()));
    }

    final custom = map['customizations'];
    Map<dynamic, dynamic> customMap = {};
    if (custom is Map) customMap = Map<dynamic, dynamic>.from(custom);

    return ProductModel(
      id: id,
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      categoryId: (map['categoryId'] ?? '') as String,
      images: images,
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0,
      isVeg: map['isVeg'] != false,
      isBestSeller: map['isBestSeller'] == true,
      isFeatured: map['isFeatured'] == true,
      isActive: map['isActive'] != false,
      outletIds: outletIds,
      sizes: parseOptions(customMap['sizes']),
      crusts: parseOptions(customMap['crusts']),
      toppings: parseOptions(customMap['toppings']),
      addons: parseOptions(customMap['addons']),
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  bool availableAt(String? outletId) {
    if (outletId == null || outletIds.isEmpty) return true;
    return outletIds.contains(outletId);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> opts(List<CustomOption> list) =>
        {for (final o in list) o.id: o.toMap()};
    final imagesMap = <String, dynamic>{};
    for (var i = 0; i < images.length; i++) {
      imagesMap['$i'] = images[i];
    }
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'images': imagesMap,
      'basePrice': basePrice,
      'isVeg': isVeg,
      'isBestSeller': isBestSeller,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'outletIds': {for (final id in outletIds) id: true},
      'customizations': {
        'sizes': opts(sizes),
        'crusts': opts(crusts),
        'toppings': opts(toppings),
        'addons': opts(addons),
      },
      'avgRating': avgRating,
      'reviewCount': reviewCount,
    };
  }
}
