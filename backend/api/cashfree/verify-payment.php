<?php

declare(strict_types=1);

/**
 * GET /api/cashfree/verify-payment.php?order_id=CF_XXXXXXXX
 *
 * Verifies the payment directly with Cashfree using the server secret and only
 * then updates Firebase Realtime Database. The client callback is never trusted
 * on its own. The endpoint is idempotent: once an order is PAID it returns the
 * stored status without reapplying side effects.
 */

require_once __DIR__ . '/../../helpers/bootstrap.php';
// DISABLED: Cashfree integration replaced by UPI Intent (app-side upi://pay flow).
// require_once __DIR__ . '/../../services/firebase_service.php';
// require_once __DIR__ . '/../../services/cashfree_service.php';
// require_once __DIR__ . '/../../services/order_service.php';
// require_once __DIR__ . '/../../helpers/auth_guard.php';

// -----------------------------------------------------------------------------
// Cashfree online payments are disabled. The app now pays through UPI Intent.
// The original implementation is kept below for reference and is unreachable.
// -----------------------------------------------------------------------------
throw new ApiException('Cashfree payments are disabled. Online payments now use UPI Intent.', 410);

$uid = require_firebase_uid();

$orderId = trim((string) ($_GET['order_id'] ?? ''));
if ($orderId === '') {
    $body = json_body();
    $orderId = trim((string) ($body['order_id'] ?? ''));
}
if ($orderId === '') {
    throw new ApiException('Order id is required.', 400);
}

$config = brisko_config();

$cashfree = new CashfreeService($config['cashfree']);
$service = new OrderService(firebase_service(), $config['pricing']);

$order = $service->getLocalOrder($orderId);
if ($order === null) {
    throw new ApiException('Order not found.', 404);
}
if ((string) ($order['userId'] ?? '') !== $uid) {
    throw new ApiException('You are not allowed to view this order.', 403);
}

$amount = (float) ($order['finalAmount'] ?? $order['amount'] ?? 0);
$current = strtoupper((string) ($order['paymentStatus'] ?? 'PENDING'));

// Idempotent: a confirmed payment is never re-processed.
if ($current === 'PAID') {
    json_response([
        'success' => true,
        'order_id' => $orderId,
        'status' => 'PAID',
        'amount' => $amount,
        'message' => 'Payment already confirmed.',
    ]);
}

try {
    $resolved = $service->resolveCashfreeStatus($orderId, $cashfree);
} catch (\Throwable $e) {
    // Do not wrongly mark anything. Ask the client to retry shortly.
    error_log('[brisko] verify-payment failed for ' . $orderId . ': ' . $e->getMessage());
    json_response([
        'success' => true,
        'order_id' => $orderId,
        'status' => $current,
        'amount' => $amount,
        'message' => 'Payment verification is in progress. Please wait.',
    ]);
}

$service->markOrderStatus($orderId, $resolved['paymentStatus'], $resolved['cashfreeOrderStatus'], $order);

$messages = [
    'PAID' => 'Payment confirmed.',
    'FAILED' => 'Payment failed. Please try again.',
    'USER_DROPPED' => 'Payment was cancelled. Please try again.',
    'PENDING' => 'Payment verification is in progress. Please wait.',
];

json_response([
    'success' => true,
    'order_id' => $orderId,
    'status' => $resolved['paymentStatus'],
    'amount' => $amount,
    'message' => $messages[$resolved['paymentStatus']] ?? 'Payment status updated.',
]);
