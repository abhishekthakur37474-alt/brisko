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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 40, backgroundColor: AppColors.success, child: Icon(Icons.check, color: AppColors.white, size: 40)),
              const SizedBox(height: 20),
              Text('Order placed!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(orderId, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              const Text('We are firing up the oven. Track status live from Orders.'),
              const SizedBox(height: 28),
              PrimaryButton(label: 'Track order', onPressed: () => context.go('/order/$orderId')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
            ],
          ),
        ),
      ),
    );
  }
}
