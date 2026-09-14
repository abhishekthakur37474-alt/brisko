import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_motion.dart';

Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (context) {
      return _GlassSheetFrame(child: builder(context));
    },
  );
}

class _GlassSheetFrame extends StatefulWidget {
  final Widget child;
  const _GlassSheetFrame({required this.child});

  @override
  State<_GlassSheetFrame> createState() => _GlassSheetFrameState();
}

class _GlassSheetFrameState extends State<_GlassSheetFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.modal)..forward();
    _scale = Tween(begin: 0.98, end: 1.0).animate(CurvedAnimation(parent: _c, curve: AppMotion.overshoot));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: ColoredBox(
            color: AppColors.white.withValues(alpha: 0.92),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}