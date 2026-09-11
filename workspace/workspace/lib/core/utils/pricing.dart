import '../constants/app_strings.dart';
import '../../features/cart/cart_item.dart';
import '../../features/offers_coupons/coupon_model.dart';
import '../../features/loyalty/loyalty_config.dart';

class PriceBreakdown {
  final double subtotal;
  final double gstAmount;
  final double deliveryCharge;
  final double couponDiscount;
  final double loyaltyDiscount;
  final int loyaltyPointsUsed;
  final double finalAmount;

  const PriceBreakdown({
    required this.subtotal,
    required this.gstAmount,
    required this.deliveryCharge,
    required this.couponDiscount,
    required this.loyaltyDiscount,
    required this.loyaltyPointsUsed,
    required this.finalAmount,
  });
}

class Pricing {
  static double itemPrice({
    required double basePrice,
    double sizeModifier = 0,
    double crustModifier = 0,
    double toppingsTotal = 0,
    double addonsTotal = 0,
  }) {
    return basePrice + sizeModifier + crustModifier + toppingsTotal + addonsTotal;
  }

  static PriceBreakdown compute({
    required List<CartItem> items,
    CouponModel? coupon,
    LoyaltyConfig? loyalty,
    int availablePoints = 0,
    bool redeemLoyalty = false,
    int? requestedPoints,
    bool isFirstOrder = false,
    int couponUsageCount = 0,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final gstAmount = double.parse((subtotal * AppStrings.gstRate).toStringAsFixed(2));
    final deliveryCharge = subtotal >= AppStrings.freeDeliveryThreshold
        ? 0.0
        : AppStrings.flatDeliveryFee;

    var couponDiscount = 0.0;
    if (coupon != null && coupon.isValidNow) {
      final eligible = subtotal >= coupon.minOrderValue &&
          (!coupon.isFirstOrderOnly || isFirstOrder) &&
          couponUsageCount < coupon.usageLimitPerUser;
      if (eligible) {
        couponDiscount = coupon.discountType == 'percent'
            ? subtotal * (coupon.discountValue / 100)
            : coupon.discountValue;
        if (coupon.maxDiscount > 0 && couponDiscount > coupon.maxDiscount) {
          couponDiscount = coupon.maxDiscount;
        }
        couponDiscount = double.parse(couponDiscount.toStringAsFixed(2));
      }
    }

    var loyaltyDiscount = 0.0;
    var pointsUsed = 0;
    if (redeemLoyalty && loyalty != null && availablePoints >= loyalty.minPointsToRedeem) {
      final maxByConfig = loyalty.maxPointsUsablePerOrder;
      final maxByBalance = availablePoints;
      final maxByOrder = loyalty.redemptionValuePerPoint <= 0
          ? 0
          : ((subtotal + gstAmount + deliveryCharge - couponDiscount) /
                  loyalty.redemptionValuePerPoint)
              .floor();
      var cap = [maxByConfig, maxByBalance, maxByOrder].reduce((a, b) => a < b ? a : b);
      if (requestedPoints != null && requestedPoints < cap) cap = requestedPoints;
      if (cap < 0) cap = 0;
      pointsUsed = cap;
      loyaltyDiscount = double.parse(
        (pointsUsed * loyalty.redemptionValuePerPoint).toStringAsFixed(2),
      );
    }

    var finalAmount = subtotal + gstAmount + deliveryCharge - couponDiscount - loyaltyDiscount;
    if (finalAmount < 0) finalAmount = 0;
    finalAmount = double.parse(finalAmount.toStringAsFixed(2));

    return PriceBreakdown(
      subtotal: subtotal,
      gstAmount: gstAmount,
      deliveryCharge: deliveryCharge,
      couponDiscount: couponDiscount,
      loyaltyDiscount: loyaltyDiscount,
      loyaltyPointsUsed: pointsUsed,
      finalAmount: finalAmount,
    );
  }
}
