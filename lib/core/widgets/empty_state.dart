import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'brisko_logo.dart';

class EmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final reduce = MediaQuery.of(context).disableAnimations;
                return Transform.translate(
                  offset: Offset(0, reduce ? 0 : -4 + 8 * _c.value),
                  child: child,
                );
              },
              child: widget.icon != null
                  ? Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Icon(widget.icon, color: AppColors.primary, size: 34),
                    )
                  : CustomPaint(size: const Size(80, 80), painter: PizzaSlicePainter()),
            ),
            const SizedBox(height: 24),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(onPressed: widget.onAction, child: Text(widget.actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}