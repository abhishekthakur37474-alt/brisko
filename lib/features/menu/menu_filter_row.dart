import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/glass_sheet.dart';

enum MenuSort { priceLowHigh, priceHighLow, popularity, rating }

extension MenuSortX on MenuSort {
  String get label => switch (this) {
        MenuSort.priceLowHigh => 'Price (Low to High)',
        MenuSort.priceHighLow => 'Price (High to Low)',
        MenuSort.popularity => 'Popularity',
        MenuSort.rating => 'Rating',
      };
}

Future<MenuSort?> showMenuSortSheet(BuildContext context, MenuSort current) {
  return showGlassSheet<MenuSort>(
    context: context,
    builder: (c) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black),
            ),
            const SizedBox(height: 8),
            ...MenuSort.values.map((option) {
              final active = option == current;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.black,
                    fontSize: 15,
                  ),
                ),
                trailing: active
                    ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                    : const Icon(Icons.circle_outlined, color: AppColors.border, size: 22),
                onTap: () => Navigator.pop(c, option),
              );
            }),
          ],
        ),
      );
    },
  );
}

class MenuFilterRow extends StatelessWidget {
  final bool vegOnly;
  final bool nonVegOnly;
  final VoidCallback onVegToggle;
  final VoidCallback onNonVegToggle;
  final VoidCallback onSortTap;

  const MenuFilterRow({
    super.key,
    required this.vegOnly,
    required this.nonVegOnly,
    required this.onVegToggle,
    required this.onNonVegToggle,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          _FilterChip(
            label: 'Veg',
            selected: vegOnly,
            activeColor: AppColors.veg,
            icon: const _VegDot(),
            onTap: onVegToggle,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Non Veg',
            selected: nonVegOnly,
            activeColor: AppColors.nonVeg,
            icon: const _NonVegMark(),
            onTap: onNonVegToggle,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sort',
            selected: false,
            activeColor: AppColors.black,
            icon: const Icon(Icons.swap_vert, size: 15, color: AppColors.muted),
            onTap: onSortTap,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final Widget icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? activeColor.withValues(alpha: 0.45) : AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? activeColor : AppColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VegDot extends StatelessWidget {
  const _VegDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.veg, width: 1.3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: AppColors.veg, shape: BoxShape.circle),
      ),
    );
  }
}

class _NonVegMark extends StatelessWidget {
  const _NonVegMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 13,
      height: 13,
      child: CustomPaint(painter: _TriangleOutlinePainter(AppColors.nonVeg)),
    );
  }
}

class _TriangleOutlinePainter extends CustomPainter {
  final Color color;
  const _TriangleOutlinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 1)
      ..lineTo(size.width - 1, size.height - 1)
      ..lineTo(1, size.height - 1)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.62), 1.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TriangleOutlinePainter oldDelegate) => oldDelegate.color != color;
}
