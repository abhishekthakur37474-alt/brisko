import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_button.dart';

class OrderConfirmScreen extends StatelessWidget {
  final String orderId;
  const OrderConfirmScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 20),
              Text('Order placed!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(orderId, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'We are firing up the oven. Track status live from Orders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: 'Track order', onPressed: () => context.go('/order/$orderId')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
