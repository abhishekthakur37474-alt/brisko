<?php

declare(strict_types=1);

/**
 * POST /api/upi/verify-payment.php
 *
 * Called by Flutter right after the customer's UPI app reports a successful
 * payment. The authenticated UID comes from the Firebase ID token, never from
 * the body. The server:
 *
 *   - recomputes the payable amount from the RTDB catalog and rejects any order
 *     whose amount was tampered with;
 *   - conditionally confirms the transaction with the configured verifier
 *     (UPI_VERIFY_URL) and only then flips the order to `paid`;
 *   - when no verifier is configured, leaves the order `pending` so an admin can
 *     reconcile it against the bank statement.
 *
 * The client can never mark a UPI order as paid (enforced by the RTDB rules);
 * only this endpoint (Admin SDK) may do so.
 */

require_once __DIR__ . '/../../helpers/bootstrap.php';
require_once __DIR__ . '/../../services/firebase_service.php';
require_once __DIR__ . '/../../services/order_service.php';
require_once __DIR__ . '/../../services/upi_payment_service.php';
require_once __DIR__ . '/../../helpers/auth_guard.php';

require_post();

$uid = require_firebase_uid();

$body = json_body();
if ($body === []) {
    throw new ApiException('Invalid request.', 400);
}

$config = brisko_config();

$service = new UpiPaymentService(
    firebase_service(),
    new OrderService(firebase_service(), $config['pricing']),
    $config['upi']
);

$result = $service->verify($uid, $body);

json_response([
    'success' => true,
    'order_id' => $result['order_id'],
    'paymentStatus' => $result['paymentStatus'],
    'verification' => $result['verification'],
    'amount' => $result['amount'],
    'message' => $result['message'],
]);
