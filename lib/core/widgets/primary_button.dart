import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_motion.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.color,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _enabled => !widget.loading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.color == null
        ? AppColors.primaryGradient
        : LinearGradient(colors: [widget.color!, widget.color!]);
    return AnimatedScale(
      scale: _pressed && _enabled ? 0.97 : 1,
      duration: AppMotion.micro,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: gradient,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _enabled ? widget.onPressed : null,
              onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(14),
              child: Opacity(
                opacity: _enabled ? 1 : 0.45,
                child: Center(
                  child: widget.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, size: 20, color: AppColors.white),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                widget.label,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}