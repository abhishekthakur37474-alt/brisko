<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/includes/bootstrap.php';

header('Content-Type: application/json');

$raw = (string) file_get_contents('php://input');
$payload = json_decode($raw, true);
if (!is_array($payload)) {
    $payload = $_POST;
}

$orderId = (string) ($payload['orderId'] ?? $payload['order_id'] ?? '');
$status = (string) ($payload['paymentStatus'] ?? $payload['status'] ?? 'paid');
if ($orderId === '') {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'orderId required']);
    exit;
}

try {
    $rtdb = brisko_rtdb();
    $order = $rtdb->get('orders/' . $orderId);
    if (!is_array($order)) {
        throw new RuntimeException('Order not found.');
    }
    $rtdb->patch('orders/' . $orderId, [
        'paymentStatus' => $status === 'failed' ? 'failed' : 'paid',
        'updatedAt' => brisko_now_ms(),
    ]);
    echo json_encode(['ok' => true]);
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
