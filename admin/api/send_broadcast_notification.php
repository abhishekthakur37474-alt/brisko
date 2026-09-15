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
    $title = trim((string) ($_POST['title'] ?? ''));
    $body = trim((string) ($_POST['body'] ?? ''));
    $segment = (string) ($_POST['segment'] ?? 'all');
    if ($title === '' || $body === '') {
        throw new InvalidArgumentException('Title and message are required.');
    }
    $rtdb = brisko_rtdb();
    $users = brisko_map($rtdb->get('users'));
    $sentInbox = 0;
    $tokens = [];
    foreach ($users as $uid => $user) {
        if (!is_array($user)) {
            continue;
        }
        if (!empty($user['isBlocked'])) {
            continue;
        }
        if ($segment === 'with_orders') {
            $orders = $rtdb->get('userOrders/' . $uid);
            if (!is_array($orders) || $orders === []) {
                continue;
            }
        }
        brisko_notify_user($rtdb, (string) $uid, $title, $body, 'promo');
        $sentInbox++;
        foreach (brisko_user_tokens($user) as $t) {
            $tokens[] = $t;
        }
    }
    $pushed = (new FcmClient(brisko_config()))->sendToTokens($tokens, $title, $body, ['type' => 'promo']);
    echo json_encode(['ok' => true, 'inbox' => $sentInbox, 'push' => $pushed]);
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
