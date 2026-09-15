<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/includes/bootstrap.php';

header('Content-Type: application/json');

// Fail closed: this receiver must never let an unauthenticated caller mark an
// order as paid. A valid shared secret (set BRISKO_PAYMENT_WEBHOOK_SECRET) is
// required. The Cashfree flow uses the signed api/cashfree/webhook.php instead.
$secret = (string) (brisko_config()['payment_webhook_secret'] ?? '');
$provided = (string) ($_SERVER['HTTP_X_WEBHOOK_SECRET'] ?? ($_POST['secret'] ?? ''));
if ($secret === '' || $provided === '' || !hash_equals($secret, $provided)) {
    http_response_code(401);
    echo json_encode(['ok' => false, 'error' => 'Unauthorized']);
    exit;
}

$raw = (string) file_get_contents('php://input');
$payload = json_decode($raw, true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$orderId = (string) ($payload['orderId'] ?? $payload['order_id'] ?? '');
$status = strtolower((string) ($payload['paymentStatus'] ?? $payload['status'] ?? 'paid'));
if ($orderId === '') {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'orderId required']);
    exit;
}

$allowed = ['paid', 'failed', 'pending', 'user_dropped'];
if (!in_array($status, $allowed, true)) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'Invalid paymentStatus']);
    exit;
}

try {
    $rtdb = brisko_rtdb();
    $order = $rtdb->get('orders/' . $orderId);
    if (!is_array($order)) {
        throw new RuntimeException('Order not found.');
    }
    // Never downgrade an order that is already paid.
    if (strtolower((string) ($order['paymentStatus'] ?? '')) === 'paid' && $status !== 'paid') {
        echo json_encode(['ok' => true, 'message' => 'Already paid.']);
        exit;
    }
    $rtdb->patch('orders/' . $orderId, [
        'paymentStatus' => $status,
        'updatedAt' => brisko_now_ms(),
    ]);
    echo json_encode(['ok' => true]);
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
