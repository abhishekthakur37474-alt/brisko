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

  static Uri sendOtp() => Uri.parse('$baseUrl/api/send-otp.php');
  static Uri verifyOtp() => Uri.parse('$baseUrl/api/verify-otp.php');
  static Uri resendOtp() => Uri.parse('$baseUrl/api/resend-otp.php');
  static Uri logout() => Uri.parse('$baseUrl/api/logout.php');
}
