class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.sortOrder,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return CategoryModel(
      id: id,
      name: (map['name'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] != false,
    );
  }
}
