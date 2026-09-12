import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final map = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: map.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: map.$2, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.2),
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
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0));
      default:
        return (AppColors.grey, AppColors.black);
    }
  }
}
