class LoyaltyConfig {
  final double pointsPerRupeeSpent;
  final double redemptionValuePerPoint;
  final int minPointsToRedeem;
  final int maxPointsUsablePerOrder;
  final int pointsExpiryDays;

  const LoyaltyConfig({
    this.pointsPerRupeeSpent = 0.05,
    this.redemptionValuePerPoint = 1,
    this.minPointsToRedeem = 50,
    this.maxPointsUsablePerOrder = 200,
    this.pointsExpiryDays = 90,
  });

  factory LoyaltyConfig.fromMap(Map<dynamic, dynamic> map) {
    return LoyaltyConfig(
      pointsPerRupeeSpent: (map['pointsPerRupeeSpent'] as num?)?.toDouble() ?? 0.05,
      redemptionValuePerPoint: (map['redemptionValuePerPoint'] as num?)?.toDouble() ?? 1,
      minPointsToRedeem: (map['minPointsToRedeem'] as num?)?.toInt() ?? 50,
      maxPointsUsablePerOrder: (map['maxPointsUsablePerOrder'] as num?)?.toInt() ?? 200,
      pointsExpiryDays: (map['pointsExpiryDays'] as num?)?.toInt() ?? 90,
    );
  }

  Map<String, dynamic> toMap() => {
        'pointsPerRupeeSpent': pointsPerRupeeSpent,
        'redemptionValuePerPoint': redemptionValuePerPoint,
        'minPointsToRedeem': minPointsToRedeem,
        'maxPointsUsablePerOrder': maxPointsUsablePerOrder,
        'pointsExpiryDays': pointsExpiryDays,
      };
}

class LoyaltyEntry {
  final String id;
  final String? orderId;
  final int pointsEarned;
  final int pointsRedeemed;
  final int balanceAfter;
  final int createdAt;

  const LoyaltyEntry({
    required this.id,
    this.orderId,
    required this.pointsEarned,
    required this.pointsRedeemed,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory LoyaltyEntry.fromMap(String id, Map<dynamic, dynamic> map) {
    return LoyaltyEntry(
      id: id,
      orderId: map['orderId'] as String?,
      pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 0,
      pointsRedeemed: (map['pointsRedeemed'] as num?)?.toInt() ?? 0,
      balanceAfter: (map['balanceAfter'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}
