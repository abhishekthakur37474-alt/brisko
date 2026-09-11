import 'package:flutter_test/flutter_test.dart';

import 'package:brisko/core/utils/pricing.dart';
import 'package:brisko/features/cart/cart_item.dart';

void main() {
  test('pricing formula matches spec', () {
    const item = CartItem(
      id: '1',
      productId: 'p',
      name: 'Margherita',
      image: '',
      selectedSize: 'Regular',
      selectedCrust: 'Classic',
      toppings: {},
      addons: {},
      quantity: 2,
      unitPrice: 199,
      totalPrice: 398,
    );
    final price = Pricing.compute(items: [item]);
    expect(price.subtotal, 398);
    expect(price.gstAmount, 19.9);
    expect(price.deliveryCharge, 40);
    expect(price.finalAmount, 457.9);
  });
}
