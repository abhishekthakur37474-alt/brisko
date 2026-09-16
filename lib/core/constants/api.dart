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
    defaultValue: 'https://briskopizza.com/backend',
  );

  // ===========================================================================
  // Online payments now use UPI Intent. The Cashfree integration was commented
  // out in favour of UPI Intent and is kept below for reference only.
  // ===========================================================================
  //
  // /// Cashfree environment used by the Flutter SDK to build the payment session.
  // ///
  // /// This must match CASHFREE_ENVIRONMENT on the PHP backend:
  // ///   flutter run --dart-define=CASHFREE_ENV=SANDBOX
  // static const String cashfreeEnvironment = String.fromEnvironment(
  //   'CASHFREE_ENV',
  //   defaultValue: 'SANDBOX',
  // );

  /// Merchant UPI VPA (UPI ID) that receives the UPI Intent payment.
  ///
  /// This is a public payee address, not a secret. Set it per environment:
  ///   flutter run --dart-define=UPI_MERCHANT_VPA=brisko@ybl
  static const String upiMerchantVpa = String.fromEnvironment(
    'UPI_MERCHANT_VPA',
    defaultValue: 'brisko@upi',
  );

  /// Payee display name shown in the UPI app while paying.
  ///
  ///   flutter run --dart-define=UPI_MERCHANT_NAME=Brisko%20Pizza
  static const String upiMerchantName = String.fromEnvironment(
    'UPI_MERCHANT_NAME',
    defaultValue: 'Brisko Pizza',
  );

  static Uri sendOtp() => Uri.parse('$baseUrl/api/send-otp.php');
  static Uri verifyOtp() => Uri.parse('$baseUrl/api/verify-otp.php');
  static Uri resendOtp() => Uri.parse('$baseUrl/api/resend-otp.php');
  static Uri logout() => Uri.parse('$baseUrl/api/logout.php');

  // --- Cashfree online payment endpoints (disabled, kept for reference) ------
  // static Uri createOnlineOrder() => Uri.parse('$baseUrl/api/cashfree/create-order.php');
  // static Uri verifyOnlinePayment(String orderId) => Uri.parse(
  //       '$baseUrl/api/cashfree/verify-payment.php',
  //     ).replace(queryParameters: {'order_id': orderId});
}
