class OtpVerifyResult {
  final String customToken;
  final bool isNewUser;
  final String uid;
  final String phone;

  const OtpVerifyResult({
    required this.customToken,
    required this.isNewUser,
    this.uid = '',
    this.phone = '',
  });

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResult(
      customToken: (json['customToken'] ?? '').toString(),
      isNewUser: json['isNewUser'] == true,
      uid: (json['uid'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}

class OtpException implements Exception {
  final String message;
  final int? statusCode;

  const OtpException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
