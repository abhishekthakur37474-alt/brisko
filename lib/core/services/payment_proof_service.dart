import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/api.dart';
import 'firebase_service.dart';

/// Raised for any payment-screenshot upload problem. Message is safe to show.
class PaymentProofException implements Exception {
  final String message;
  const PaymentProofException(this.message);

  @override
  String toString() => message;
}

/// Uploads the customer's payment screenshot to the Brisko backend, which hosts
/// it (ImgBB) and returns the public URL stored on the order.
class PaymentProofService {
  PaymentProofService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 60);

  Future<String> upload(XFile file) async {
    final user = FirebaseService.instance.auth.currentUser;
    if (user == null) {
      throw const PaymentProofException('Please sign in to continue.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const PaymentProofException('Please sign in to continue.');
    }

    late http.Response res;
    try {
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', ApiConfig.uploadPaymentProof());
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'payment-proof.jpg',
        ),
      );
      final streamed = await _client.send(request).timeout(_timeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const PaymentProofException('Upload timed out. Please try again.');
    } catch (_) {
      throw const PaymentProofException('Could not upload the screenshot. Please try again.');
    }

    Map<String, dynamic> body = <String, dynamic>{};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      body = <String, dynamic>{};
    }

    final url = (body['url'] ?? '').toString();
    if (res.statusCode >= 200 && res.statusCode < 300 && url.isNotEmpty) {
      return url;
    }
    throw PaymentProofException(
      (body['message'] ?? 'Could not upload the screenshot. Please try again.').toString(),
    );
  }
}
