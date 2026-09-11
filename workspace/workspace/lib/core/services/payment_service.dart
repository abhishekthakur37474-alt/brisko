class PaymentResult {
  final bool success;
  final String status;
  final String? transactionId;
  final String? message;

  const PaymentResult({
    required this.success,
    required this.status,
    this.transactionId,
    this.message,
  });
}

abstract class PaymentGateway {
  Future<PaymentResult> pay({
    required double amount,
    required String orderId,
    required String currency,
  });
}

class CodPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> pay({
    required double amount,
    required String orderId,
    required String currency,
  }) async {
    return const PaymentResult(success: true, status: 'pending');
  }
}

class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> pay({
    required double amount,
    required String orderId,
    required String currency,
  }) async {
    return const PaymentResult(
      success: false,
      status: 'unavailable',
      message: 'Online payment coming soon',
    );
  }
}

class PaymentService {
  PaymentGateway gatewayFor(String method) {
    if (method == 'online') return MockPaymentGateway();
    return CodPaymentGateway();
  }
}
