import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_motion.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final map = _style(status);
    final live = status == 'preparing' || status == 'out_for_delivery' || status == 'ready';
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: map.$1, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            _PulseDot(color: map.$2),
            const SizedBox(width: 6),
          ],
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(color: map.$2, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  (Color, Color) _style(String s) {
    switch (s) {
      case 'delivered':
        return (AppColors.successSoft, AppColors.success);
      case 'cancelled':
        return (AppColors.primarySoft, AppColors.primary);
      case 'preparing':
      case 'ready':
        return (AppColors.warningSoft, const Color(0xFF9A6700));
      case 'out_for_delivery':
        return (AppColors.liveBlueSoft, AppColors.liveBlue);
      default:
        return (AppColors.grey, AppColors.black);
    }
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}