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
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  rupees(product.basePrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const SizedBox(width: 6),
              _AddButton(onTap: () => addProductToCart(context, ref, product)),
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
              AspectRatio(aspectRatio: 1.28, child: image),
              body,
            ],
          );

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/product/${product.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              boxShadow: AppColors.softShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
              ? const ColoredBox(color: AppColors.grey, child: Icon(Icons.local_pizza, color: AppColors.primary, size: 40))
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
        if (product.isBestSeller)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('BEST', style: TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _pressed = true);
        widget.onTap();
        Future<void>.delayed(AppMotion.micro, () {
          if (mounted) setState(() => _pressed = false);
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: AppMotion.micro,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: AppColors.white),
                SizedBox(width: 2),
                Text(
                  'ADD',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}