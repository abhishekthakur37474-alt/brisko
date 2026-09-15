<?php

declare(strict_types=1);

require_once __DIR__ . '/auth_middleware.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'POST required']);
    exit;
}

try {
    $orderId = trim((string) ($_POST['orderId'] ?? ''));
    if ($orderId === '') {
        throw new InvalidArgumentException('Order id required.');
    }
    $rtdb = brisko_rtdb();
    $order = $rtdb->get('orders/' . $orderId);
    if (!is_array($order)) {
        throw new RuntimeException('Order not found.');
    }
    $dir = (string) (brisko_config()['invoice_dir'] ?? dirname(__DIR__) . '/invoices');
    PdfInvoice::writeHtml($dir, $orderId, $order);
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = (string) ($_SERVER['HTTP_HOST'] ?? 'localhost');
    $base = rtrim(dirname((string) ($_SERVER['SCRIPT_NAME'] ?? '')), '/api');
    $url = $scheme . '://' . $host . $base . '/invoices/' . rawurlencode($orderId) . '.html';
    $rtdb->patch('orders/' . $orderId, ['invoiceUrl' => $url]);
    echo json_encode(['ok' => true, 'url' => $url]);
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
