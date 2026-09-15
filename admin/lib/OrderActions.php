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
    $rtdb->patch('orders/' . $orderId, [
        'orderStatus' => $status,
        'updatedAt' => $now,
        'statusTimestamps' => $stamps,
    ]);
    $order['orderStatus'] = $status;
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
