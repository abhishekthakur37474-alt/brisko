<?php

declare(strict_types=1);

require_once __DIR__ . '/auth_middleware.php';
require_once dirname(__DIR__) . '/lib/OrderActions.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'POST required']);
    exit;
}

try {
    $orderId = trim((string) ($_POST['orderId'] ?? ''));
    $status = trim((string) ($_POST['status'] ?? ''));
    echo json_encode(brisko_update_order_status(brisko_rtdb(), $orderId, $status));
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
