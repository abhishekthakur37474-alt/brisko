import 'package:upi_intent/upi_intent.dart';

import '../constants/api.dart';

/// Raised for any UPI Intent problem. The message is always safe to show.
class UpiIntentException implements Exception {
  final String message;
  const UpiIntentException(this.message);

  @override
  String toString() => message;
}

/// Result of asking the UPI app to process a payment.
class UpiIntentResult {
  /// True only when the UPI app explicitly reported the transaction as SUCCESS.
  final bool paid;

  /// Transaction id reported by the UPI app (Android only).
  final String? transactionId;

  /// UPI response code reported by the app (Android only).
  final String? responseCode;

  final UpiTransactionStatus? status;

  const UpiIntentResult({
    required this.paid,
    this.transactionId,
    this.responseCode,
    this.status,
  });
}

/// Drives the UPI Intent (deep link) payment flow.
///
/// The customer's UPI app is launched with a `upi://pay` request built from the
/// merchant VPA/name configured through dart-defines. On Android the chosen UPI
/// app returns the transaction result, which lets checkout place the order only
/// after a confirmed payment. On iOS the UPI app cannot report the result, so
/// the payment is treated as unconfirmed and the order is not placed.
///
/// Built on `upi_intent`, not `upi_pay` (abandoned; `getInstalledUpiApplications`
/// unreliably returns an empty list on modern Android versions even with the
/// manifest `<queries>` block in place).
class UpiIntentService {
  UpiIntentService();

  String get merchantVpa => ApiConfig.upiMerchantVpa;
  String get merchantName => ApiConfig.upiMerchantName;

  bool get isConfigured =>
      merchantVpa.contains('@') && merchantVpa.toLowerCase() != 'brisko@upi';

  /// UPI apps installed on this device and able to process a payment.
  Future<List<UpiApp>> installedApps() async {
    try {
      return await UpiIntent.getInstalledApps();
    } catch (_) {
      throw const UpiIntentException('Unable to find UPI apps on this device.');
    }
  }

  /// Launches [app] to pay [amount] to the merchant.
  ///
  /// [transactionRef] is echoed back by the UPI app so the payment can be tied
  /// back to this checkout attempt.
  Future<UpiIntentResult> pay({
    required UpiApp app,
    required double amount,
    required String transactionRef,
    String? note,
  }) async {
    if (!isConfigured) {
      throw const UpiIntentException(
        'UPI payments are not configured yet. Please use Cash on Delivery.',
      );
    }
    if (amount <= 0) {
      throw const UpiIntentException('Invalid payment amount.');
    }

    UpiResponse? response;
    try {
      response = await UpiIntent.payWithApp(
        app: app,
        payment: UpiPayment(
          payeeVpa: merchantVpa,
          payeeName: merchantName,
          amount: amount,
          transactionNote: note ?? 'Brisko order',
          transactionRefId: transactionRef,
        ),
      );
    } catch (_) {
      throw const UpiIntentException('Unable to open the UPI app. Please try again.');
    }

    // A null response means the user backed out of the UPI app / picker
    // without a result being reported. Treat as unconfirmed, same as the old
    // "unknown" status, so the order is never placed on ambiguous outcomes.
    if (response == null) {
      return const UpiIntentResult(paid: false, status: UpiTransactionStatus.unknown);
    }

    return UpiIntentResult(
      paid: response.isSuccess,
      transactionId: response.transactionId,
      responseCode: response.responseCode,
      status: response.status,
    );
  }
}