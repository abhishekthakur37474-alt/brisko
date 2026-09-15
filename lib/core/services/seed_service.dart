import 'firebase_service.dart';

class SeedService {
  static const outletId = 'outlet_delhi_cp';

  Future<void> seedIfEmpty() async {
    await repairCategoryImages();
    final snap = await FirebaseService.instance.ref('categories').get();
    if (snap.exists) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final year = DateTime.now().year + 1;
    final validTo = DateTime(year, 12, 31).millisecondsSinceEpoch;

    final data = <String, dynamic>{
      'outlets': {
        outletId: {
          'name': 'Brisko Connaught Place',
          'address': 'Block A, Connaught Place, New Delhi',
          'lat': 28.6328,
          'lng': 77.2197,
          'serviceRadiusKm': 25,
          'isActive': true,
          'contactNumber': '+919876543210',
          'openTime': '11:00',
          'closeTime': '23:30',
        },
        'outlet_mumbai_bandra': {
          'name': 'Brisko Bandra',
          'address': 'Linking Road, Bandra West, Mumbai',
          'lat': 19.0596,
          'lng': 72.8295,
          'serviceRadiusKm': 25,
          'isActive': true,
          'contactNumber': '+919876543211',
          'openTime': '11:00',
          'closeTime': '23:30',
        },
      },
      'categories': {
        'pizzas': {'name': 'Pizzas', 'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400', 'sortOrder': 1, 'isActive': true},
        'burgers': {'name': 'Burgers', 'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400', 'sortOrder': 2, 'isActive': true},
        'sides': {'name': 'Sides', 'imageUrl': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400', 'sortOrder': 3, 'isActive': true},
        'beverages': {'name': 'Beverages', 'imageUrl': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400', 'sortOrder': 4, 'isActive': true},
        'combos': {'name': 'Combos', 'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400', 'sortOrder': 5, 'isActive': true},
        'offers': {'name': 'Offers', 'imageUrl': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400', 'sortOrder': 6, 'isActive': true},
      },
      'products': _products(),
      'coupons': {
        'BRISKO50': {
          'description': 'Flat Rs 50 off on orders above Rs 299',
          'discountType': 'flat',
          'discountValue': 50,
          'minOrderValue': 299,
          'maxDiscount': 50,
          'validFrom': now - 86400000,
          'validTo': validTo,
          'usageLimitPerUser': 5,
          'isFirstOrderOnly': false,
          'isActive': true,
        },
        'FIRST100': {
          'description': 'Rs 100 off on your first order above Rs 399',
          'discountType': 'flat',
          'discountValue': 100,
          'minOrderValue': 399,
          'maxDiscount': 100,
          'validFrom': now - 86400000,
          'validTo': validTo,
          'usageLimitPerUser': 1,
          'isFirstOrderOnly': true,
          'isActive': true,
        },
        'PIZZA20': {
          'description': '20% off up to Rs 120',
          'discountType': 'percent',
          'discountValue': 20,
          'minOrderValue': 249,
          'maxDiscount': 120,
          'validFrom': now - 86400000,
          'validTo': validTo,
          'usageLimitPerUser': 3,
          'isFirstOrderOnly': false,
          'isActive': true,
        },
      },
      'loyaltyConfig': {
        'pointsPerRupeeSpent': 0.05,
        'redemptionValuePerPoint': 1,
        'minPointsToRedeem': 50,
        'maxPointsUsablePerOrder': 200,
        'pointsExpiryDays': 90,
        'minOrderValueForPoints': 0,
      },
    };

    await FirebaseService.instance.ref('/').update(data);
  }

  Future<void> repairCategoryImages() async {
    const images = {
      'pizzas': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      'burgers': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      'sides': 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
      'beverages': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400',
      'combos': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      'offers': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
    };
    for (final entry in images.entries) {
      try {
        final ref = FirebaseService.instance.ref('categories/${entry.key}');
        final snap = await ref.get();
        if (!snap.exists) continue;
        final map = snap.value is Map ? Map<dynamic, dynamic>.from(snap.value as Map) : <dynamic, dynamic>{};
        final current = (map['imageUrl'] ?? '').toString();
        final broken = current.isEmpty || current.contains('1544145945');
        if (broken) {
          await ref.update({'imageUrl': entry.value});
        }
      } catch (_) {}
    }
  }

  Map<String, dynamic> _products() {
    Map<String, dynamic> pizzaCustom() => {
          'sizes': {
            'regular': {'name': 'Regular', 'price': 0},
            'medium': {'name': 'Medium', 'price': 80},
            'large': {'name': 'Large', 'price': 160},
          },
          'crusts': {
            'classic': {'name': 'Classic Hand Tossed', 'price': 0},
            'thin': {'name': 'Thin Crust', 'price': 30},
            'cheese': {'name': 'Cheese Burst', 'price': 70},
          },
          'toppings': {
            'mushroom': {'name': 'Mushroom', 'price': 40},
            'olives': {'name': 'Olives', 'price': 40},
            'jalapeno': {'name': 'Jalapeno', 'price': 35},
            'paneer': {'name': 'Paneer', 'price': 50},
            'chicken': {'name': 'Chicken', 'price': 60},
            'pepperoni': {'name': 'Pepperoni', 'price': 70},
          },
          'addons': {
            'extra_cheese': {'name': 'Extra Cheese', 'price': 40},
            'dip': {'name': 'Garlic Dip', 'price': 25},
          },
        };

    final outlets = {outletId: true, 'outlet_mumbai_bandra': true};

    return {
      'margherita': {
        'name': 'Margherita',
        'description': 'Classic tomato, mozzarella and basil. Simple, bold, perfect.',
        'categoryId': 'pizzas',
        'images': {0: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800'},
        'basePrice': 199,
        'isVeg': true,
        'isBestSeller': true,
        'isFeatured': true,
        'isActive': true,
        'outletIds': outlets,
        'customizations': pizzaCustom(),
        'avgRating': 4.6,
        'reviewCount': 128,
      },
      'farmhouse': {
        'name': 'Farmhouse',
        'description': 'Onion, capsicum, tomato and mushroom on a cheesy base.',
        'categoryId': 'pizzas',
        'images': {0: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800'},
        'basePrice': 279,
        'isVeg': true,
        'isBestSeller': true,
        'isFeatured': false,
        'isActive': true,
        'outletIds': outlets,
        'customizations': pizzaCustom(),
        'avgRating': 4.5,
        'reviewCount': 96,
      },
      'pepperoni_feast': {
        'name': 'Pepperoni Feast',
        'description': 'Loaded pepperoni with extra mozzarella.',
        'categoryId': 'pizzas',
        'images': {0: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=800'},
        'basePrice': 349,
        'isVeg': false,
        'isBestSeller': true,
        'isFeatured': true,
        'isActive': true,
        'outletIds': outlets,
        'customizations': pizzaCustom(),
        'avgRating': 4.8,
        'reviewCount': 210,
      },
      'bbq_chicken': {
        'name': 'BBQ Chicken',
        'description': 'Smoky BBQ sauce, grilled chicken and onions.',
        'categoryId': 'pizzas',
        'images': {0: 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?w=800'},
        'basePrice': 369,
        'isVeg': false,
        'isBestSeller': false,
        'isFeatured': true,
        'isActive': true,
        'outletIds': outlets,
        'customizations': pizzaCustom(),
        'avgRating': 4.4,
        'reviewCount': 72,
      },
      'paneer_tikka': {
        'name': 'Paneer Tikka',
        'description': 'Tandoori paneer, onion and capsicum with spicy masala.',
        'categoryId': 'pizzas',
        'images': {0: 'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=800'},
        'basePrice': 329,
        'isVeg': true,
        'isBestSeller': false,
        'isFeatured': true,
        'isActive': true,
        'outletIds': outlets,
        'customizations': pizzaCustom(),
        'avgRating': 4.7,
        'reviewCount': 154,
      },
      'classic_burger': {
        'name': 'Classic Veg Burger',
        'description': 'Crispy patty, lettuce, tomato and Brisko sauce.',
        'categoryId': 'burgers',
        'images': {0: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=800'},
        'basePrice': 129,
        'isVeg': true,
        'isBestSeller': true,
        'isFeatured': false,
        'isActive': true,
        'outletIds': outlets,
        'customizations': {
          'addons': {
            'cheese': {'name': 'Cheese Slice', 'price': 20},
            'patty': {'name': 'Extra Patty', 'price': 40},
          },
        },
        'avgRating': 4.2,
        'reviewCount': 41,
      },
      'chicken_burger': {
        'name': 'Crispy Chicken Burger',
        'description': 'Fried chicken fillet with spicy mayo.',
        'categoryId': 'burgers',
        'images': {0: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800'},
        'basePrice': 159,
        'isVeg': false,
        'isBestSeller': false,
        'isFeatured': true,
        'isActive': true,
        'outletIds': outlets,
        'customizations': {
          'addons': {
            'cheese': {'name': 'Cheese Slice', 'price': 20},
            'patty': {'name': 'Extra Patty', 'price': 50},
          },
        },
        'avgRating': 4.3,
        'reviewCount': 38,
      },
      'garlic_bread': {
        'name': 'Garlic Breadsticks',
        'description': 'Buttery garlic bread with herbs.',
        'categoryId': 'sides',
        'images': {0: 'https://images.unsplash.com/photo-1619535860434-ba1d8fa12536?w=800'},
        'basePrice': 99,
        'isVeg': true,
        'isBestSeller': true,
        'isFeatured': false,
        'isActive': true,
        'outletIds': outlets,
        'avgRating': 4.5,
        'reviewCount': 88,
      },
      'fries': {
        'name': 'Peri Peri Fries',
        'description': 'Crispy fries tossed in peri peri seasoning.',
        'categoryId': 'sides',
        'images': {0: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=800'},
        'basePrice': 89,
        'isVeg': true,
        'isBestSeller': false,
        'isFeatured': false,
        'isActive': true,
        'outletIds': outlets,
        'avgRating': 4.1,
        'reviewCount': 29,
      },
      'coke': {
        'name': 'Coca-Cola',
        'description': 'Chilled 330ml can.',
        'categoryId': 'beverages',
        'images': {0: 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=800'},
        'basePrice': 49,
        'isVeg': true,
        'isBestSeller': false,
        'isFeatured': false,
        'isActive': true,
        'outletIds': outlets,
        'avgRating': 4.0,
        'reviewCount': 12,
      },
      'combo_solo': {
        'name': 'Solo Combo',
        'description': 'Regular pizza + fries + coke. Best value for one.',
        'categoryId': 'combos',
        'images': {0: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800'},
        'basePrice': 299,
        'isVeg': true,
        'isBestSeller': true,
        'isFeatured': true,
        'isActive': true,
        'outletIds': outlets,
        'avgRating': 4.6,
        'reviewCount': 67,
      },
      'offer_buy1': {
        'name': 'Buy 1 Get 1 Medium',
        'description': 'Any two medium pizzas at a special price.',
        'categoryId': 'offers',
        'images': {0: 'https://images.unsplash.com/photo-1601924582970-9238bcb495d3?w=800'},
        'basePrice': 499,
        'isVeg': true,
        'isBestSeller': false,
        'isFeatured': true,
        'isActive': true,
        'outletIds': outlets,
        'avgRating': 4.4,
        'reviewCount': 23,
      },
    };
  }
}
