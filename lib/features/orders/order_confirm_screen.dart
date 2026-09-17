import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../payment/payment_settings.dart';
import 'orders_controller.dart';

class OrderConfirmScreen extends ConsumerWidget {
  final String orderId;
  const OrderConfirmScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId)).valueOrNull;
    final settings = ref.watch(paymentSettingsProvider).valueOrNull ?? const PaymentSettings.empty();
    // Online (manual UPI/QR) orders are created pending until an admin confirms
    // the uploaded payment proof. Until then the customer waits.
    final awaitingPayment = order?.isPaymentUnderReview ?? false;
    return awaitingPayment ? _WaitingScreen(orderId: orderId, waitMinutes: settings.waitMinutes) : _PlacedScreen(orderId: orderId);
  }
}

class _PlacedScreen extends StatelessWidget {
  final String orderId;
  const _PlacedScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return _ConfirmScaffold(
      orderId: orderId,
      iconBg: AppColors.successSoft,
      icon: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
      title: 'Order placed!',
      body: 'We are firing up the oven. Track status live from Orders.',
    );
  }
}

class _WaitingScreen extends StatelessWidget {
  final String orderId;
  final int waitMinutes;
  const _WaitingScreen({required this.orderId, required this.waitMinutes});

  @override
  Widget build(BuildContext context) {
    final label = waitMinutes <= 1 ? '1 minute' : '$waitMinutes minutes';
    return _ConfirmScaffold(
      orderId: orderId,
      iconBg: AppColors.primarySoft,
      icon: const Icon(Icons.schedule_outlined, color: AppColors.primary, size: 48),
      title: 'Order placed!',
      body: 'Wait for $label to confirm your order.\n'
          'We are verifying your UPI payment. Your order will proceed once approved.',
    );
  }
}

class _ConfirmScaffold extends StatelessWidget {
  final String orderId;
  final Color iconBg;
  final Widget icon;
  final String title;
  final String body;

  const _ConfirmScaffold({
    required this.orderId,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.body,
  });

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
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Center(child: icon),
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(orderId, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
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
