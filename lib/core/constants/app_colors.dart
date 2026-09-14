import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE30613);
  static const Color primaryDark = Color(0xFFB10510);
  static const Color primarySoft = Color(0xFFFFE8EA);
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFF6F4F2);
  static const Color cream = Color(0xFFFFF8F3);
  static const Color warmBg = Color(0xFFF8F7F3);
  static const Color surface = Color(0xFFF1F1EF);
  static const Color success = Color(0xFF2E7D32);
  static const Color successSoft = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningSoft = Color(0xFFFFF4E0);
  static const Color text = Color(0xFF111111);
  static const Color muted = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFE8E4E0);
  static const Color veg = Color(0xFF2E7D32);
  static const Color nonVeg = Color(0xFFE30613);
  static const Color overlay = Color(0x99000000);
  static const Color shadow = Color(0x24000000);
  static const Color liveBlue = Color(0xFF1565C0);
  static const Color liveBlueSoft = Color(0xFFE3F2FD);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111111), Color(0xFF1C1C1C), Color(0xFF2A0A0C)],
  );

  static List<BoxShadow> get softShadow => const [
        BoxShadow(color: shadow, blurRadius: 16, offset: Offset(0, 6)),
      ];
}
