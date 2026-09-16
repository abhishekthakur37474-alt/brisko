import 'package:upi_pay/upi_pay.dart';

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
class UpiIntentService {
  UpiIntentService({UpiPay? upiPay}) : _upiPay = upiPay ?? UpiPay();

  final UpiPay _upiPay;

  String get merchantVpa => ApiConfig.upiMerchantVpa;
  String get merchantName => ApiConfig.upiMerchantName;

  bool get isConfigured =>
      merchantVpa.contains('@') && merchantVpa.toLowerCase() != 'brisko@upi';

  /// UPI apps installed on this device and able to process a payment.
  Future<List<ApplicationMeta>> installedApps() async {
    try {
      return await _upiPay.getInstalledUpiApplications();
    } catch (_) {
      throw const UpiIntentException('Unable to find UPI apps on this device.');
    }
  }

  /// Launches [app] to pay [amount] to the merchant.
  ///
  /// [transactionRef] is echoed back by the UPI app so the payment can be tied
  /// back to this checkout attempt.
  Future<UpiIntentResult> pay({
    required UpiApplication app,
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

    UpiTransactionResponse response;
    try {
      response = await _upiPay.initiateTransaction(
        app: app,
        receiverUpiAddress: merchantVpa,
        receiverName: merchantName,
        transactionRef: transactionRef,
        amount: amount.toStringAsFixed(2),
        transactionNote: note ?? 'Brisko order',
      );
    } catch (_) {
      throw const UpiIntentException('Unable to open the UPI app. Please try again.');
    }

    final status = response.status;
    // Android-only fields: reading them on iOS throws UnsupportedError.
    String? txnId;
    String? responseCode;
    try {
      txnId = response.txnId;
      responseCode = response.responseCode;
    } catch (_) {
      txnId = null;
      responseCode = null;
    }

    return UpiIntentResult(
      paid: status == UpiTransactionStatus.success,
      transactionId: txnId,
      responseCode: responseCode,
      status: status,
    );
  }
}
