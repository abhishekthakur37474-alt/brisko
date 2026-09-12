class CouponModel {
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final double maxDiscount;
  final int validFrom;
  final int validTo;
  final int usageLimitPerUser;
  final bool isFirstOrderOnly;
  final bool isActive;

  const CouponModel({
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.maxDiscount,
    required this.validFrom,
    required this.validTo,
    required this.usageLimitPerUser,
    required this.isFirstOrderOnly,
    required this.isActive,
  });

  factory CouponModel.fromMap(String code, Map<dynamic, dynamic> map) {
    return CouponModel(
      code: code,
      description: (map['description'] ?? '') as String,
      discountType: (map['discountType'] ?? 'flat') as String,
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0,
      minOrderValue: (map['minOrderValue'] as num?)?.toDouble() ?? 0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble() ?? 0,
      validFrom: (map['validFrom'] as num?)?.toInt() ?? 0,
      validTo: (map['validTo'] as num?)?.toInt() ?? 0,
      usageLimitPerUser: (map['usageLimitPerUser'] as num?)?.toInt() ?? 99,
      isFirstOrderOnly: map['isFirstOrderOnly'] == true,
      isActive: map['isActive'] != false,
    );
  }

  bool get isValidNow {
    if (!isActive) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (validFrom > 0 && now < validFrom) return false;
    if (validTo > 0 && now > validTo) return false;
    return true;
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
        'maxDiscount': maxDiscount,
        'validFrom': validFrom,
        'validTo': validTo,
        'usageLimitPerUser': usageLimitPerUser,
        'isFirstOrderOnly': isFirstOrderOnly,
        'isActive': isActive,
      };
}
