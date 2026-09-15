class ApiConfig {
  ApiConfig._();

  /// Base URL of the Brisko PHP backend.
  ///
  /// The PHP backend is the ONLY thing allowed to talk to ApiTxt and to mint
  /// Firebase custom tokens. The ApiTxt auth key and Firebase service account
  /// must never reach this app.
  ///
  /// Override at build/run time:
  ///   flutter run --dart-define=API_BASE_URL=https://api.brisko.example
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://blackxmarket.shop/brisko-api',
  );

  /// Cashfree environment used by the Flutter SDK to build the payment session.
  ///
  /// This must match CASHFREE_ENVIRONMENT on the PHP backend:
  ///   flutter run --dart-define=CASHFREE_ENV=SANDBOX
  static const String cashfreeEnvironment = String.fromEnvironment(
    'CASHFREE_ENV',
    defaultValue: 'SANDBOX',
  );

  static Uri sendOtp() => Uri.parse('$baseUrl/api/send-otp.php');
  static Uri verifyOtp() => Uri.parse('$baseUrl/api/verify-otp.php');
  static Uri resendOtp() => Uri.parse('$baseUrl/api/resend-otp.php');
  static Uri logout() => Uri.parse('$baseUrl/api/logout.php');

  static Uri createOnlineOrder() => Uri.parse('$baseUrl/api/cashfree/create-order.php');
  static Uri verifyOnlinePayment(String orderId) => Uri.parse(
        '$baseUrl/api/cashfree/verify-payment.php',
      ).replace(queryParameters: {'order_id': orderId});
}
