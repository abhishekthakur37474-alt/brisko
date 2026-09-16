import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';

/// Admin-configured online payment details shown to the customer on the
/// manual UPI/QR payment screen (`settings/payment` in RTDB).
class PaymentSettings {
  final String qrImageUrl;
  final String upiId;
  final String payeeName;
  final String instructions;
  final int waitMinutes;

  const PaymentSettings({
    this.qrImageUrl = '',
    this.upiId = '',
    this.payeeName = '',
    this.instructions = '',
    this.waitMinutes = 5,
  });

  const PaymentSettings.empty() : this();

  /// True when the customer can actually pay (a UPI ID or a QR is configured).
  bool get isConfigured => upiId.trim().isNotEmpty || qrImageUrl.trim().isNotEmpty;

  factory PaymentSettings.fromMap(Map<dynamic, dynamic> map) {
    final wait = (map['waitMinutes'] as num?)?.toInt() ?? 5;
    return PaymentSettings(
      qrImageUrl: (map['qrImageUrl'] ?? '').toString().trim(),
      upiId: (map['upiId'] ?? '').toString().trim(),
      payeeName: (map['payeeName'] ?? '').toString().trim(),
      instructions: (map['instructions'] ?? '').toString().trim(),
      waitMinutes: wait < 1 ? 5 : wait,
    );
  }
}

final paymentSettingsProvider = StreamProvider<PaymentSettings>((ref) {
  return FirebaseService.instance.ref('settings/payment').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is Map) {
      return PaymentSettings.fromMap(Map<dynamic, dynamic>.from(val));
    }
    return const PaymentSettings.empty();
  });
});
