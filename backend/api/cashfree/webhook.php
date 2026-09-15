<?php

declare(strict_types=1);

/**
 * POST /api/cashfree/webhook.php
 *
 * Additional, server-to-server payment notification channel. Every request must
 * carry a valid Cashfree signature (verified against the raw body). The webhook
 * is idempotent and never downgrades an order that is already PAID.
 *
 * Register this URL in the Cashfree dashboard (Developers > Webhooks) for the
 * current environment (Sandbox and Production are configured separately).
 */

require_once __DIR__ . '/../../helpers/bootstrap.php';
require_once __DIR__ . '/../../services/firebase_service.php';
require_once __DIR__ . '/../../services/cashfree_service.php';
require_once __DIR__ . '/../../services/order_service.php';

// The webhook is not user-authenticated: trust comes from the signature only.
$rawBody = file_get_contents('php://input');
$rawBody = is_string($rawBody) ? $rawBody : '';

$headers = function_exists('getallheaders') ? getallheaders() : [];
$headers = is_array($headers) ? $headers : [];

$getHeader = static function (string $name) use ($headers): string {
    foreach ($headers as $key => $value) {
        if (strtolower((string) $key) === $name) {
            return (string) $value;
        }
    }
    return '';
};

$signature = $getHeader('x-webhook-signature');
$timestamp = $getHeader('x-webhook-timestamp');
$idempotencyKey = $getHeader('x-idempotency-header');

$config = brisko_config();
$cashfree = new CashfreeService($config['cashfree']);

if (!$cashfree->verifyWebhookSignature($rawBody, $signature, $timestamp)) {
    error_log('[brisko] cashfree webhook rejected: invalid signature');
    json_response(['success' => false, 'message' => 'Invalid signature.'], 401);
}

$payload = json_decode($rawBody, true);
if (!is_array($payload)) {
    json_response(['success' => false, 'message' => 'Invalid payload.'], 400);
}

$service = new OrderService(firebase_service(), $config['pricing']);
$webhookRef = firebase_service()->ref('cashfreeWebhooks');

// Idempotency: Cashfree delivers webhooks at least once.
if ($idempotencyKey !== '') {
    $safeKey = preg_replace('/[^A-Za-z0-9_.-]/', '_', $idempotencyKey);
    if (is_string($safeKey) && $safeKey !== '') {
        $seen = $webhookRef->getChild($safeKey)->getValue();
        if ($seen === true) {
            json_response(['success' => true, 'message' => 'Already processed.']);
        }
        $webhookRef->getChild($safeKey)->set(true);
    }
}

$eventType = strtoupper((string) ($payload['type'] ?? ''));
$orderId = (string) ($payload['data']['order']['order_id'] ?? '');
$paymentStatus = strtoupper((string) ($payload['data']['payment']['payment_status'] ?? ''));

if ($orderId === '') {
    json_response(['success' => true, 'message' => 'Ignored: no order id.']);
}

$order = $service->getLocalOrder($orderId);
if ($order === null) {
    error_log('[brisko] cashfree webhook for unknown order ' . $orderId);
    json_response(['success' => true, 'message' => 'Ignored: unknown order.']);
}

$current = strtoupper((string) ($order['paymentStatus'] ?? 'PENDING'));
if ($current === 'PAID') {
    json_response(['success' => true, 'message' => 'Already paid.']);
}

$isSuccessEvent = $paymentStatus === 'SUCCESS' || $eventType === 'PAYMENT_SUCCESS_WEBHOOK';

if ($isSuccessEvent) {
    // Confirm with Cashfree before granting anything.
    try {
        $resolved = $service->resolveCashfreeStatus($orderId, $cashfree);
    } catch (\Throwable $e) {
        error_log('[brisko] webhook confirmation failed for ' . $orderId . ': ' . $e->getMessage());
        json_response(['success' => false, 'message' => 'Verification failed.'], 503);
    }

    if ($resolved['paymentStatus'] !== 'PAID') {
        json_response(['success' => true, 'message' => 'Not paid yet.']);
    }

    $service->markOrderStatus($orderId, 'PAID', $resolved['cashfreeOrderStatus'], $order);
    json_response(['success' => true, 'message' => 'Order marked as paid.']);
}

$map = [
    'FAILED' => 'FAILED',
    'USER_DROPPED' => 'USER_DROPPED',
    'CANCELLED' => 'FAILED',
    'VOID' => 'FAILED',
    'EXPIRED' => 'FAILED',
];
$mapped = $map[$paymentStatus] ?? null;

if ($mapped !== null) {
    $cfStatus = strtoupper((string) ($payload['data']['order']['order_status'] ?? $paymentStatus));
    $service->markOrderStatus($orderId, $mapped, $cfStatus, $order);
}

json_response(['success' => true, 'message' => 'Webhook processed.']);
