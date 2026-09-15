import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pricing.dart';
import '../../core/widgets/glass_sheet.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/veg_badge.dart';
import '../cart/cart_controller.dart';
import '../location/store_status.dart';
import '../menu/product_model.dart';

Future<void> showCustomizeSheet(BuildContext context, ProductModel product) async {
  await showGlassSheet(
    context: context,
    builder: (_) => CustomizeSheet(product: product),
  );
}

Future<void> addProductToCart(BuildContext context, WidgetRef ref, ProductModel product) async {
  final status = ref.read(storeStatusProvider);
  if (status.isClosed) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Brisko is closed. Opens ${status.nextOpenLabel ?? 'soon'}.')),
      );
    }
    return;
  }
  if (product.hasCustomizations) {
    await showCustomizeSheet(context, product);
    return;
  }
  try {
    await ref.read(cartControllerProvider).addCustomized(
          productId: product.id,
          name: product.name,
          image: product.image,
          isVeg: product.isVeg,
          unitPrice: product.basePrice,
          selectedSize: '',
          selectedCrust: '',
          toppings: const {},
          addons: const {},
          quantity: 1,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class CustomizeSheet extends ConsumerStatefulWidget {
  final ProductModel product;
  const CustomizeSheet({super.key, required this.product});

  @override
  ConsumerState<CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends ConsumerState<CustomizeSheet> {
  String? _size;
  String? _crust;
  final Set<String> _toppings = {};
  final Set<String> _addons = {};
  int _qty = 1;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _size = p.sizes.isNotEmpty ? p.sizes.first.id : null;
    _crust = p.crusts.isNotEmpty ? p.crusts.first.id : null;
  }

  double _price() {
    final p = widget.product;
    final sizeMod = p.sizes.where((s) => s.id == _size).firstOrNull?.price ?? 0;
    final crustMod = p.crusts.where((s) => s.id == _crust).firstOrNull?.price ?? 0;
    final toppings = p.toppings.where((t) => _toppings.contains(t.id)).fold<double>(0, (s, t) => s + t.price);
    final addons = p.addons.where((t) => _addons.contains(t.id)).fold<double>(0, (s, t) => s + t.price);
    return Pricing.itemPrice(
      basePrice: p.basePrice,
      sizeModifier: sizeMod,
      crustModifier: crustMod,
      toppingsTotal: toppings,
      addonsTotal: addons,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final unit = _price();
    final store = ref.watch(storeStatusProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.image.isEmpty
                      ? const SizedBox(width: 56, height: 56, child: ColoredBox(color: AppColors.grey, child: Icon(Icons.local_pizza, color: AppColors.primary)))
                      : CachedNetworkImage(imageUrl: product.image, width: 56, height: 56, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          VegBadge(isVeg: product.isVeg),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Customize your order', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (product.sizes.isNotEmpty) ...[
                  Text('Size', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...product.sizes.map((s) => _OptionRow(
                        title: s.name,
                        price: s.price,
                        selected: _size == s.id,
                        onTap: () => setState(() => _size = s.id),
                      )),
                  const SizedBox(height: 16),
                ],
                if (product.crusts.isNotEmpty) ...[
                  Text('Crust', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...product.crusts.map((s) => _OptionRow(
                        title: s.name,
                        price: s.price,
                        selected: _crust == s.id,
                        onTap: () => setState(() => _crust = s.id),
                      )),
                  const SizedBox(height: 16),
                ],
                if (product.toppings.isNotEmpty) ...[
                  Text('Toppings', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...product.toppings.map((s) => _OptionRow(
                        title: s.name,
                        price: s.price,
                        selected: _toppings.contains(s.id),
                        onTap: () => setState(() {
                          if (_toppings.contains(s.id)) {
                            _toppings.remove(s.id);
                          } else {
                            _toppings.add(s.id);
                          }
                        }),
                      )),
                  const SizedBox(height: 16),
                ],
                if (product.addons.isNotEmpty) ...[
                  Text('Add-ons', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...product.addons.map((s) => _OptionRow(
                        title: s.name,
                        price: s.price,
                        selected: _addons.contains(s.id),
                        onTap: () => setState(() {
                          if (_addons.contains(s.id)) {
                            _addons.remove(s.id);
                          } else {
                            _addons.add(s.id);
                          }
                        }),
                      )),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  QuantityStepper(
                    value: _qty,
                    onMinus: () => setState(() {
                      if (_qty > 1) _qty--;
                    }),
                    onPlus: () => setState(() => _qty++),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: store.isClosed ? 'Closed · Opens ${store.nextOpenLabel ?? 'soon'}' : 'Add ${rupees(unit * _qty)}',
                      loading: _adding,
                      onPressed: store.isClosed
                          ? null
                          : () async {
                        setState(() => _adding = true);
                        try {
                          // NOTE: store the backend option *id*, not the display
                          // name, since the PHP backend looks these values up
                          // directly as keys in product.customizations.{group}.
                          final toppings = {for (final t in product.toppings.where((t) => _toppings.contains(t.id))) t.id: t.price};
                          final addons = {for (final t in product.addons.where((t) => _addons.contains(t.id))) t.id: t.price};
                          await ref.read(cartControllerProvider).addCustomized(
                                productId: product.id,
                                name: product.name,
                                image: product.image,
                                isVeg: product.isVeg,
                                unitPrice: unit,
                                selectedSize: product.sizes.where((s) => s.id == _size).firstOrNull?.id ?? '',
                                selectedCrust: product.crusts.where((s) => s.id == _crust).firstOrNull?.id ?? '',
                                toppings: toppings,
                                addons: addons,
                                quantity: _qty,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                          }
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                        } finally {
                          if (mounted) setState(() => _adding = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            if (price > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '+${rupees(price)}',
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : AppColors.white,
                border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1.6),
              ),
              child: selected ? const Icon(Icons.check, size: 14, color: AppColors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}