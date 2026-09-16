import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import 'firebase_service.dart';

/// Outcome of a server-side UPI Intent verification attempt.
class UpiVerificationResult {
  /// `paid`, `pending`, `failed` or `amount_mismatch`.
  final String paymentStatus;

  /// `verified`, `pending`, `rejected` or `not_required`.
  final String verification;

  final String message;

  const UpiVerificationResult({
    required this.paymentStatus,
    required this.verification,
    required this.message,
  });

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
  bool get needsManualReview =>
      verification.toLowerCase() == 'pending' ||
      verification.toLowerCase() == 'rejected';

  factory UpiVerificationResult.fromJson(Map<String, dynamic> json) {
    return UpiVerificationResult(
      paymentStatus: (json['paymentStatus'] ?? 'pending').toString(),
      verification: (json['verification'] ?? 'pending').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

/// Talks to the Brisko PHP backend to verify a UPI Intent payment.
///
/// The client can never mark an online order as paid: the order is created with
/// `paymentStatus: pending` and this call asks the server (which owns the
/// merchant credentials / verification endpoint) to confirm it. When the server
/// has no automatic verifier configured it leaves the order pending so an admin
/// can reconcile it against the bank statement.
class UpiVerificationService {
  UpiVerificationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 20);

  Future<UpiVerificationResult> verify({
    required String orderId,
    required double amount,
    String upiTxnId = '',
    String upiResponseCode = '',
    String upiPayerVpa = '',
    String transactionRef = '',
  }) async {
    final user = FirebaseService.instance.auth.currentUser;
    if (user == null) {
      throw Exception('Login required');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }

    late http.Response res;
    try {
      res = await _client
          .post(
            ApiConfig.verifyUpiPayment(),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'orderId': orderId,
              'amount': amount,
              'upiTxnId': upiTxnId,
              'upiResponseCode': upiResponseCode,
              'upiPayerVpa': upiPayerVpa,
              'transactionRef': transactionRef,
            }),
          )
          .timeout(_timeout);
    } catch (_) {
      return const UpiVerificationResult(
        paymentStatus: 'pending',
        verification: 'pending',
        message: 'We could not reach the verification server. Your payment will be confirmed shortly.',
      );
    }

    Map<String, dynamic> body = <String, dynamic>{};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      body = <String, dynamic>{};
    }

    final ok = res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true;
    if (!ok) {
      return UpiVerificationResult(
        paymentStatus: (body['paymentStatus'] ?? 'pending').toString(),
        verification: (body['verification'] ?? 'pending').toString(),
        message: (body['message'] ?? 'Your payment is awaiting confirmation.').toString(),
      );
    }
    return UpiVerificationResult.fromJson(body);
  }
}
