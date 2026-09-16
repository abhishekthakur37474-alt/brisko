import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/payment_proof_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pricing.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../addresses/address_model.dart';
import '../cart/cart_item.dart';
import '../location/location_controller.dart';
import '../orders/orders_controller.dart';
import '../payment/payment_settings.dart';

/// Everything checkout has already validated, handed to the payment screen so
/// the order can be created only after the customer submits their payment proof.
class OnlinePaymentArgs {
  final List<CartItem> items;
  final AddressModel address;
  final String outletId;
  final PriceBreakdown price;
  final String? couponCode;
  final String notes;
  final OrderMode orderMode;
  final String receiverName;
  final String receiverPhone;

  const OnlinePaymentArgs({
    required this.items,
    required this.address,
    required this.outletId,
    required this.price,
    required this.couponCode,
    required this.notes,
    required this.orderMode,
    required this.receiverName,
    required this.receiverPhone,
  });
}

class PaymentScreen extends ConsumerStatefulWidget {
  final OnlinePaymentArgs args;
  const PaymentScreen({super.key, required this.args});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _txn = TextEditingController();
  final _picker = ImagePicker();
  final _proof = PaymentProofService();

  XFile? _screenshot;
  bool _submitting = false;

  @override
  void dispose() {
    _txn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(paymentSettingsProvider).valueOrNull ?? const PaymentSettings.empty();
    final amount = widget.args.price.finalAmount;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const BriskoTopBar(
            title: 'Online Payment',
            subtitle: 'Pay via UPI',
            circularBack: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _AmountCard(amount: amount),
                const SizedBox(height: 20),
                if (!settings.isConfigured)
                  _warningCard(
                    'Online payment is not available right now. Please go back and choose Cash on Delivery.',
                  )
                else ...[
                  if (settings.qrImageUrl.isNotEmpty) ...[
                    const _SectionTitle('Scan & pay'),
                    const SizedBox(height: 10),
                    _QrCard(url: settings.qrImageUrl, payeeName: settings.payeeName),
                    const SizedBox(height: 20),
                  ],
                  const _SectionTitle('UPI ID'),
                  const SizedBox(height: 10),
                  _UpiIdCard(upiId: settings.upiId, amount: amount),
                ],
                const SizedBox(height: 20),
                const _SectionTitle('Payment screenshot'),
                const SizedBox(height: 10),
                _ScreenshotCard(
                  screenshot: _screenshot,
                  onPick: _pickScreenshot,
                  onClear: () => setState(() => _screenshot = null),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Transaction ID / UTR'),
                const SizedBox(height: 10),
                TextField(
                  controller: _txn,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 425812345678',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                    filled: true,
                    fillColor: AppColors.warmBg,
                  ),
                ),
                if (settings.instructions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _infoCard(settings.instructions),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, -6)),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: PrimaryButton(
            label: 'Submit Payment  •  ${rupees(amount)}',
            loading: _submitting,
            onPressed: _submitting ? null : () => _submit(settings),
          ),
        ),
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked != null && mounted) setState(() => _screenshot = picked);
    } catch (_) {
      _snack('Could not open the gallery.');
    }
  }

  Future<void> _submit(PaymentSettings settings) async {
    if (!settings.isConfigured) {
      _snack('Online payment is not available right now. Please choose Cash on Delivery.');
      return;
    }
    final txn = _txn.text.trim();
    if (_screenshot == null) {
      _snack('Please upload your payment screenshot.');
      return;
    }
    if (txn.isEmpty) {
      _snack('Please enter the transaction ID / UTR.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final proofUrl = await _proof.upload(_screenshot!);
      if (!mounted) return;

      final id = await ref.read(ordersControllerProvider).placeOrder(
            items: widget.args.items,
            address: widget.args.address,
            outletId: widget.args.outletId,
            price: widget.args.price,
            paymentMethod: 'upi_intent',
            notes: widget.args.notes,
            couponCode: widget.args.couponCode,
            orderMode: widget.args.orderMode,
            receiverName: widget.args.receiverName,
            receiverPhone: widget.args.receiverPhone,
            upiTxnId: txn,
            paymentProofUrl: proofUrl,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.schedule_outlined, color: AppColors.primary, size: 40),
          title: const Text('Payment submitted'),
          content: Text(
            'Wait for ${settings.waitMinutes} minute${settings.waitMinutes == 1 ? '' : 's'} to confirm your order. '
            'We are verifying your payment; your order will be confirmed once approved.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.go('/order-confirm/$id');
    } on PaymentProofException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _warningCard(String text) => _SoftCard(
        background: AppColors.primarySoft.withValues(alpha: 0.35),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text))),
          ],
        ),
      );

  Widget _infoCard(String text) => _SoftCard(
        background: AppColors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tips_and_updates_outlined, size: 20, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppColors.muted))),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.text),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? background;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: AppColors.softShadow,
      ),
      child: child,
    );
  }
}

class _AmountCard extends StatelessWidget {
  final double amount;
  const _AmountCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount to pay', style: GoogleFonts.inter(fontSize: 13, color: AppColors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 4),
          Text(
            rupees(amount),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 28, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final String url;
  final String payeeName;
  const _QrCard({required this.url, required this.payeeName});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          if (payeeName.isNotEmpty) ...[
            Text(payeeName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.text)),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 240,
              height: 240,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(
                width: 240,
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => const SizedBox(
                width: 240,
                height: 240,
                child: Center(child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.muted)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan this QR with any UPI app',
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _UpiIdCard extends StatelessWidget {
  final String upiId;
  final double amount;
  const _UpiIdCard({required this.upiId, required this.amount});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(upiId.isEmpty ? 'UPI ID not set' : upiId,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('Pay ${rupees(amount)} to this UPI ID',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (upiId.isNotEmpty)
            IconButton(
              tooltip: 'Copy UPI ID',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: upiId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UPI ID copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

class _ScreenshotCard extends StatelessWidget {
  final XFile? screenshot;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ScreenshotCard({
    required this.screenshot,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          if (screenshot == null)
            InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: AppColors.warmBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, size: 34, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('Upload payment screenshot',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text('JPG or PNG',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<Uint8List>(
                    future: screenshot!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        width: 64,
                        height: 64,
                        color: AppColors.warmBg,
                        child: const Icon(Icons.image_outlined, color: AppColors.muted),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    screenshot!.name.isNotEmpty ? screenshot!.name : 'payment-screenshot.jpg',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                ),
                IconButton(
                  tooltip: 'Change',
                  onPressed: onPick,
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
