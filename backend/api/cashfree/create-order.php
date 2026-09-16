<?php

declare(strict_types=1);

/**
 * POST /api/cashfree/create-order.php
 *
 * Called by Flutter when the user taps "Pay". The authenticated UID comes from
 * the Firebase ID token, never from the request body. The server recomputes the
 * amount from the RTDB catalog, creates the Cashfree order and parks a PENDING
 * record under `pendingOrders/{orderId}`. The order only becomes a real,
 * customer-visible `orders/{orderId}` once the payment is confirmed as PAID, so
 * abandoning the payment gateway can never place an order.
 */

require_once __DIR__ . '/../../helpers/bootstrap.php';
// DISABLED: Cashfree integration replaced by UPI Intent (app-side upi://pay flow).
// require_once __DIR__ . '/../../services/firebase_service.php';
// require_once __DIR__ . '/../../services/cashfree_service.php';
// require_once __DIR__ . '/../../services/order_service.php';
// require_once __DIR__ . '/../../helpers/auth_guard.php';

require_post();

// -----------------------------------------------------------------------------
// Cashfree online payments are disabled. The app now pays through UPI Intent.
// The original implementation is kept below for reference and is unreachable.
// -----------------------------------------------------------------------------
throw new ApiException('Cashfree payments are disabled. Online payments now use UPI Intent.', 410);

$uid = require_firebase_uid();
$body = json_body();

if ($body === []) {
    throw new ApiException('Invalid request.', 400);
}

$config = brisko_config();

$cashfree = new CashfreeService($config['cashfree']);
$service = new OrderService(firebase_service(), $config['pricing']);

$result = $service->createOnlineOrder($uid, $body, $cashfree, $config['cashfree']);

json_response([
    'success' => true,
    'order_id' => $result['order_id'],
    'payment_session_id' => $result['payment_session_id'],
    'amount' => $result['amount'],
    'currency' => $result['currency'],
]);
