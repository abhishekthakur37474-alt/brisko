import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BLogo(),
            SizedBox(height: 16),
            Text(
              AppStrings.tagline,
              style: TextStyle(color: AppColors.white, fontSize: 16, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _BLogo extends StatelessWidget {
  const _BLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: const Text(
        'B',
        style: TextStyle(color: AppColors.white, fontSize: 52, fontWeight: FontWeight.w800),
      ),
    );
  }
}
