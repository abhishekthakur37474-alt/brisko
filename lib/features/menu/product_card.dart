import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/veg_badge.dart';
import '../product_detail/customize_sheet.dart';
import 'product_model.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final bool wide;
  const ProductCard({super.key, required this.product, this.wide = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = _image(heroTag: 'product-${product.id}');
    final customize = product.hasCustomizations;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VegBadge(isVeg: product.isVeg),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  rupees(product.basePrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _AddButton(
                      label: customize ? 'CUSTOMIZE' : 'ADD',
                      icon: customize ? Icons.tune_rounded : Icons.add,
                      onTap: () => addProductToCart(context, ref, product),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final card = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 132, child: image),
              Expanded(child: body),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(aspectRatio: 1.18, child: image),
              Expanded(child: body),
            ],
          );

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/product/${product.id}'),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: card,
            ),
          ),
        ),
      ),
    );
  }

  Widget _image({required String heroTag}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: heroTag,
          child: product.image.isEmpty
              ? const ColoredBox(
                  color: AppColors.grey,
                  child: Icon(Icons.local_pizza, color: AppColors.primary, size: 40),
                )
              : CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.cover,
                  memCacheWidth: 480,
                  fadeInDuration: AppMotion.fast,
                  placeholder: (_, __) => const ColoredBox(color: AppColors.grey),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppColors.grey,
                    child: Icon(Icons.local_pizza, color: AppColors.primary, size: 40),
                  ),
                ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x14000000), Color(0x00000000)],
            ),
          ),
        ),
        if (product.isBestSeller)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'BESTSELLER',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label == 'CUSTOMIZE' ? 'Customize' : 'Add to cart',
      child: GestureDetector(
        onTap: () {
          setState(() => _pressed = true);
          widget.onTap();
          Future<void>.delayed(AppMotion.micro, () {
            if (mounted) setState(() => _pressed = false);
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: AppMotion.micro,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 14, color: AppColors.white),
                    const SizedBox(width: 3),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.3,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
