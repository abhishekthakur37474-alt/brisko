import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/brisko_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  BriskoLogo.assetPath,
                  width: 148,
                  height: 148,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const BriskoLogo(size: 128, dark: true),
                ),
                const SizedBox(height: 22),
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.poppins(
                    color: AppColors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tagline,
                  style: GoogleFonts.inter(
                    color: AppColors.muted,
                    fontSize: 15,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
