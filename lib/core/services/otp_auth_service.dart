import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../../features/auth/otp_models.dart';

/// Talks ONLY to the Brisko PHP backend.
///
/// It never knows about ApiTxt, never holds an auth key and never generates an
/// OTP. The backend generates/verifies the OTP and returns a Firebase custom
/// token that this service hands back to the auth layer.
class OtpAuthService {
  OtpAuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 20);
  static const String _networkError = 'Please check your internet connection.';

  Future<void> sendOtp(String mobile) async {
    await _post(ApiConfig.sendOtp(), {'mobile': mobile});
  }

  Future<void> resendOtp(String mobile) async {
    await _post(ApiConfig.resendOtp(), {'mobile': mobile});
  }

  Future<void> logout() async {
    await _post(ApiConfig.logout(), const {});
  }

  Future<OtpVerifyResult> verifyOtp({required String mobile, required String otp}) async {
    final body = await _post(ApiConfig.verifyOtp(), {'mobile': mobile, 'otp': otp});
    final result = OtpVerifyResult.fromJson(body);
    if (result.customToken.isEmpty) {
      throw const OtpException('Verification failed. Please try again.');
    }
    return result;
  }

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, dynamic> payload) async {
    late http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
    } catch (_) {
      throw const OtpException(_networkError);
    }

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(res.body);
      body = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    } catch (_) {
      body = <String, dynamic>{};
    }

    final ok = res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true;
    if (!ok) {
      throw OtpException(_friendlyMessage(body, res.statusCode), statusCode: res.statusCode);
    }
    return body;
  }

  String _friendlyMessage(Map<String, dynamic> body, int status) {
    final server = (body['message'] ?? '').toString().trim();
    if (status == 429) {
      return server.isNotEmpty ? server : 'Too many attempts. Please request a new OTP later.';
    }
    if (status >= 500) {
      return server.isNotEmpty ? server : 'Unable to send OTP right now. Please try again.';
    }
    if (server.isNotEmpty) return server;
    return 'Something went wrong. Please try again.';
  }
}
