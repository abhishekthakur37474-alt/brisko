import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/pizza_loader.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/veg_badge.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_item.dart';
import 'order_model.dart';
import 'orders_controller.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int _tab = 0;

  List<CartItem> _previousItems(List<OrderModel> orders) {
    final seen = <String>{};
    final items = <CartItem>[];
    for (final order in orders) {
      if (order.orderStatus == 'cancelled') continue;
      for (final item in order.items) {
        final key = item.productId.isNotEmpty ? item.productId : item.name;
        if (seen.add(key)) items.add(item);
      }
    }
    return items;
  }

  Future<void> _reorder(CartItem item) async {
    try {
      await ref.read(cartControllerProvider).addCustomized(
            productId: item.productId,
            name: item.name,
            image: item.image,
            isVeg: item.isVeg,
            unitPrice: item.unitPrice,
            selectedSize: item.selectedSize,
            selectedCrust: item.selectedCrust,
            toppings: item.toppings,
            addons: item.addons,
            quantity: 1,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(userOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          BriskoTopBar(
            title: 'Orders',
            subtitle: 'Reorder your favorites',
            onBack: () => context.go('/home'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  _SegTab(
                    label: 'Previously Ordered',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _SegTab(
                    label: 'Order History',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              data: (orders) {
                if (_tab == 0) {
                  final items = _previousItems(orders);
                  if (items.isEmpty) {
                    return _ReorderEmpty(onExplore: () => context.go('/menu'));
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(userOrdersProvider);
                      await Future<void>.delayed(const Duration(milliseconds: 400));
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return AppCard(
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: item.image.isNotEmpty
                                      ? CachedNetworkImage(imageUrl: item.image, fit: BoxFit.cover)
                                      : Container(
                                          color: AppColors.primarySoft,
                                          child: const Icon(Icons.local_pizza, color: AppColors.primary),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        VegBadge(isVeg: item.isVeg),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      rupees(item.unitPrice),
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _reorder(item),
                                child: const Text('Reorder'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }

                if (orders.isEmpty) {
                  return _ReorderEmpty(onExplore: () => context.go('/menu'));
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(userOrdersProvider);
                    await Future<void>.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      return AppCard(
                        onTap: () => context.push('/order/${o.id}'),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'order-icon-${o.id}',
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.local_pizza, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.items.isNotEmpty ? o.items.map((e) => e.name).join(', ') : o.id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(o.createdAt)),
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 108,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(rupees(o.finalAmount), style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Align(alignment: Alignment.centerRight, child: StatusChip(status: o.orderStatus)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const PizzaLoader(message: 'Loading orders...'),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.black : AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReorderEmpty extends StatelessWidget {
  final VoidCallback onExplore;
  const _ReorderEmpty({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PizzaMascot(),
            const SizedBox(height: 28),
            const Text(
              'Seems like you have not ordered from Brisko in the recent past',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.black, height: 1.35),
            ),
            const SizedBox(height: 10),
            const Text(
              'Place your order now',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onExplore,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Explore Menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PizzaMascot extends StatelessWidget {
  const _PizzaMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 170,
      child: CustomPaint(painter: _PizzaMascotPainter()),
    );
  }
}

class _PizzaMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final crust = Paint()..color = const Color(0xFFE8B84A);
    final cheese = Paint()..color = const Color(0xFFFFE08A);
    final shadow = Paint()..color = const Color(0x142A2A2A);

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, size.height - 10), width: 78, height: 16), shadow);

    final body = Path()
      ..moveTo(cx, 18)
      ..lineTo(size.width - 18, size.height - 38)
      ..lineTo(18, size.height - 38)
      ..close();
    canvas.drawPath(body, crust);
    final inner = Path()
      ..moveTo(cx, 36)
      ..lineTo(size.width - 30, size.height - 46)
      ..lineTo(30, size.height - 46)
      ..close();
    canvas.drawPath(inner, cheese);

    final pep = Paint()..color = const Color(0xFFC62828);
    canvas.drawCircle(Offset(cx - 10, 78), 7, pep);
    canvas.drawCircle(Offset(cx + 16, 96), 6, pep);
    canvas.drawCircle(Offset(cx - 18, 108), 5.5, pep);

    final ink = Paint()
      ..color = AppColors.black
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 28, 70), width: 36, height: 36), 3.3, 1.1, false, ink);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 28, 70), width: 36, height: 36), -1.3, 1.1, false, ink);

    canvas.drawCircle(Offset(cx - 12, 86), 4.2, Paint()..color = AppColors.black);
    canvas.drawCircle(Offset(cx + 12, 86), 4.2, Paint()..color = AppColors.black);
    canvas.drawCircle(Offset(cx - 11, 85), 1.4, Paint()..color = AppColors.white);
    canvas.drawCircle(Offset(cx + 13, 85), 1.4, Paint()..color = AppColors.white);

    canvas.drawArc(Rect.fromCenter(center: Offset(cx, 102), width: 18, height: 12), 0.2, 2.7, false, ink);

    final blush = Paint()..color = const Color(0xFFFFB3B3);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 24, 98), width: 10, height: 6), blush);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 24, 98), width: 10, height: 6), blush);

    canvas.drawCircle(Offset(cx + 34, 34), 8, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(cx + 31, 32), 2.4, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
