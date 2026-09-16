<?php

declare(strict_types=1);

require_once __DIR__ . '/../api/credit_loyalty_points.php';

function brisko_update_order_status(RtdbClient $rtdb, string $orderId, string $status): array
{
    $allowed = ['confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'];
    if ($orderId === '' || !in_array($status, $allowed, true)) {
        throw new InvalidArgumentException('Invalid order or status.');
    }
    $order = $rtdb->get('orders/' . $orderId);
    if (!is_array($order)) {
        throw new RuntimeException('Order not found.');
    }
    $current = (string) ($order['orderStatus'] ?? '');
    if ($current === 'delivered' || $current === 'cancelled') {
        throw new RuntimeException('This order is already closed.');
    }
    $now = brisko_now_ms();
    $stamps = is_array($order['statusTimestamps'] ?? null) ? $order['statusTimestamps'] : [];
    $stamps[$status] = $now;
    $patch = [
        'orderStatus' => $status,
        'updatedAt' => $now,
        'statusTimestamps' => $stamps,
    ];
    // Cash on Delivery is collected when the order is delivered; keep the
    // payment status in sync so a delivered COD order no longer reads "pending".
    $paymentMethod = (string) ($order['paymentMethod'] ?? $order['payment']['method'] ?? 'cod');
    $paymentStatus = (string) ($order['paymentStatus'] ?? $order['payment']['status'] ?? '');
    if ($status === 'delivered' && strtolower($paymentMethod) === 'cod' && $paymentStatus !== 'paid') {
        $patch['paymentStatus'] = 'paid';
        $patch['paidAt'] = $now;
    }
    $rtdb->patch('orders/' . $orderId, $patch);
    $order['orderStatus'] = $status;
    if (isset($patch['paymentStatus'])) {
        $order['paymentStatus'] = $patch['paymentStatus'];
    }
    if ($status === 'delivered') {
        brisko_credit_loyalty($rtdb, $orderId, $order);
    }
    $uid = (string) ($order['userId'] ?? '');
    $title = 'Order ' . brisko_status_label($status);
    $body = 'Your Brisko order ' . $orderId . ' is now ' . brisko_status_label($status) . '.';
    $pushed = 0;
    if ($uid !== '') {
        brisko_notify_user($rtdb, $uid, $title, $body, 'order', $orderId);
        $user = $rtdb->get('users/' . $uid);
        $tokens = is_array($user) ? brisko_user_tokens($user) : [];
        $pushed = (new FcmClient(brisko_config()))->sendToTokens($tokens, $title, $body, [
            'type' => 'order',
            'orderId' => $orderId,
        ]);
    }
    return ['ok' => true, 'push' => $pushed];
}

/**
 * Admin review of a UPI Intent payment. Approving marks the order paid; marking
 * it as not received keeps it pending so the customer is not given a free pass.
 * This is the manual reconciliation path used when the backend has no automatic
 * UPI verifier configured.
 */
function brisko_review_upi_payment(RtdbClient $rtdb, string $orderId, bool $approved, string $note = ''): array
{
    $order = $rtdb->get('orders/' . $orderId);
    if (!is_array($order)) {
        throw new RuntimeException('Order not found.');
    }
    if (strtolower((string) ($order['paymentMethod'] ?? '')) !== 'upi_intent') {
        throw new RuntimeException('This order is not a UPI Intent payment.');
    }

    $now = brisko_now_ms();
    $patch = ['updatedAt' => $now];

    if ($approved) {
        $patch['paymentStatus'] = 'paid';
        $patch['paymentVerification'] = 'verified';
        $patch['paymentVerifiedAt'] = $now;
        $patch['paidAt'] = $now;
        $patch['verifiedBy'] = 'admin';
        if (trim($note) !== '') {
            $patch['verificationNote'] = trim($note);
        }
        $message = 'Your UPI payment has been confirmed.';
    } else {
        $patch['paymentStatus'] = 'pending';
        $patch['paymentVerification'] = 'rejected';
        $patch['verifiedBy'] = 'admin';
        $patch['verificationNote'] = trim($note) !== '' ? trim($note) : 'Payment not received.';
        $message = 'We could not confirm your UPI payment.';
    }

    $rtdb->patch('orders/' . $orderId, $patch);

    $uid = (string) ($order['userId'] ?? '');
    if ($uid !== '') {
        brisko_notify_user($rtdb, $uid, 'Payment update', $message . ' Order ' . $orderId . '.', 'order', $orderId);
    }

    return ['ok' => true, 'paymentStatus' => $patch['paymentStatus'], 'verification' => $patch['paymentVerification']];
}

/**
 * Marks a paid UPI order as refunded. The actual bank/UPI refund is performed by
 * the merchant; this records the outcome and a reference so the app and reports
 * reflect it. Non-destructive: the order keeps its history.
 */
function brisko_refund_upi_payment(RtdbClient $rtdb, string $orderId, string $ref = ''): array
{
    $order = $rtdb->get('orders/' . $orderId);
    if (!is_array($order)) {
        throw new RuntimeException('Order not found.');
    }
    if (strtolower((string) ($order['paymentMethod'] ?? '')) !== 'upi_intent') {
        throw new RuntimeException('Only UPI Intent orders can be refunded here.');
    }
    if (strtolower((string) ($order['paymentStatus'] ?? '')) !== 'paid') {
        throw new RuntimeException('Only a paid UPI order can be refunded.');
    }

    $now = brisko_now_ms();
    $patch = [
        'paymentStatus' => 'refunded',
        'refundStatus' => 'refunded',
        'refundedAt' => $now,
        'refundRef' => trim($ref),
        'updatedAt' => $now,
    ];
    $rtdb->patch('orders/' . $orderId, $patch);

    $uid = (string) ($order['userId'] ?? '');
    if ($uid !== '') {
        brisko_notify_user($rtdb, $uid, 'Refund processed', 'Your refund for order ' . $orderId . ' has been processed.', 'order', $orderId);
    }

    return ['ok' => true, 'refundStatus' => 'refunded'];
}
