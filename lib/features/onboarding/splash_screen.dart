import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/brisko_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BriskoLogo(size: 112, dark: false),
            const SizedBox(height: 20),
            Text(
              AppStrings.appName,
              style: GoogleFonts.poppins(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.tagline,
              style: GoogleFonts.inter(
                color: const Color(0xFFDDDDDD),
                fontSize: 15,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
