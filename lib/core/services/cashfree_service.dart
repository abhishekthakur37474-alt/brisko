import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../../features/addresses/address_model.dart';
import '../../features/cart/cart_item.dart';
import '../../features/location/location_controller.dart';

/// Raised for any online-payment problem. The message is always safe to show.
class OnlinePaymentException implements Exception {
  final String message;
  const OnlinePaymentException(this.message);

  @override
  String toString() => message;
}

/// The order + payment session returned by the PHP backend.
class OnlineOrderSession {
  final String orderId;
  final String paymentSessionId;
  final double amount;
  final String currency;

  const OnlineOrderSession({
    required this.orderId,
    required this.paymentSessionId,
    required this.amount,
    required this.currency,
  });
}

/// The server-verified payment status.
class OnlinePaymentStatus {
  final bool paid;
  final String status;
  final double amount;
  final String? message;

  const OnlinePaymentStatus({
    required this.paid,
    required this.status,
    required this.amount,
    this.message,
  });
}

/// Talks ONLY to the Brisko PHP backend for online payments.
///
/// This service never knows the Cashfree client secret or any other backend
/// credential. Order creation and payment verification both happen server-side;
/// the client only receives the order id and payment session id.
class CashfreeService {
  CashfreeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 30);
  static const String _networkError = 'Please check your internet connection and try again.';

  /// Environment the Flutter SDK must be initialised with. Kept in sync with
  /// the PHP CASHFREE_ENVIRONMENT via the CASHFREE_ENV dart-define.
  CFEnvironment get environment =>
      ApiConfig.cashfreeEnvironment.toUpperCase() == 'PRODUCTION'
          ? CFEnvironment.PRODUCTION
          : CFEnvironment.SANDBOX;

  Future<OnlineOrderSession> createOrder({
    required List<CartItem> items,
    required String outletId,
    required AddressModel address,
    required OrderMode orderMode,
    required String receiverName,
    required String receiverPhone,
    required String notes,
    String? couponCode,
    bool redeemLoyalty = false,
  }) async {
    if (items.isEmpty) {
      throw const OnlinePaymentException('Your cart is empty.');
    }

    final body = <String, dynamic>{
      'items': items
          .map(
            (item) => <String, dynamic>{
              'productId': item.productId,
              'quantity': item.quantity,
              'selectedSize': item.selectedSize,
              'selectedCrust': item.selectedCrust,
              'toppings': item.toppings.keys.toList(),
              'addons': item.addons.keys.toList(),
            },
          )
          .toList(),
      'outletId': outletId,
      'orderMode': orderMode.name,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'notes': notes,
      'couponCode': couponCode,
      'redeemLoyalty': redeemLoyalty,
      'currency': 'INR',
      'address': address.toMap(),
    };

    final response = await _send(ApiConfig.createOnlineOrder(), body: body);

    final orderId = (response['order_id'] ?? '').toString();
    final paymentSessionId = (response['payment_session_id'] ?? '').toString();
    if (orderId.isEmpty || paymentSessionId.isEmpty) {
      throw const OnlinePaymentException('Unable to start payment. Please try again.');
    }

    return OnlineOrderSession(
      orderId: orderId,
      paymentSessionId: paymentSessionId,
      amount: _toDouble(response['amount']),
      currency: (response['currency'] ?? 'INR').toString(),
    );
  }

  Future<OnlinePaymentStatus> verifyPayment(String orderId) async {
    if (orderId.isEmpty) {
      throw const OnlinePaymentException('Payment failed. Please try again.');
    }

    final response = await _send(ApiConfig.verifyOnlinePayment(orderId), method: 'GET');
    final status = (response['status'] ?? '').toString().toUpperCase();

    return OnlinePaymentStatus(
      paid: status == 'PAID',
      status: status.isEmpty ? 'PENDING' : status,
      amount: _toDouble(response['amount']),
      message: (response['message'] as String?)?.trim(),
    );
  }

  Future<Map<String, dynamic>> _send(
    Uri uri, {
    String method = 'POST',
    Map<String, dynamic>? body,
  }) async {
    final token = await _idToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    late http.Response response;
    try {
      final request = method == 'GET'
          ? _client.get(uri, headers: headers)
          : _client.post(uri, headers: headers, body: jsonEncode(body ?? const {}));
      response = await request.timeout(_timeout);
    } catch (_) {
      throw const OnlinePaymentException(_networkError);
    }

    Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(response.body);
      decoded = parsed is Map ? Map<String, dynamic>.from(parsed) : <String, dynamic>{};
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300 && decoded['success'] == true;
    if (!ok) {
      throw OnlinePaymentException(_friendlyMessage(decoded, response.statusCode));
    }

    return decoded;
  }

  Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const OnlinePaymentException('Please sign in to continue.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const OnlinePaymentException('Please sign in to continue.');
    }
    return token;
  }

  String _friendlyMessage(Map<String, dynamic> body, int status) {
    final server = (body['message'] ?? '').toString().trim();
    if (status == 401) {
      return server.isNotEmpty ? server : 'Your session has expired. Please sign in again.';
    }
    if (status >= 500) {
      return 'Unable to process the payment right now. Please try again.';
    }
    if (server.isNotEmpty) return server;
    return 'Unable to start payment. Please try again.';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
