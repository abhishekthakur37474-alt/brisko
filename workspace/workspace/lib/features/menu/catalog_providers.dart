import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import 'category_model.dart';
import 'product_model.dart';

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirebaseService.instance.ref('categories').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <CategoryModel>[];
    final list = val.entries
        .map((e) => CategoryModel.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .where((c) => c.isActive)
        .toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  });
});

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseService.instance.ref('products').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <ProductModel>[];
    return val.entries
        .map((e) => ProductModel.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .where((p) => p.isActive)
        .toList();
  });
});

final productByIdProvider = Provider.family<ProductModel?, String>((ref, id) {
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  return products.where((p) => p.id == id).firstOrNull;
});
