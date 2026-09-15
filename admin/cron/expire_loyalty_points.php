<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/includes/bootstrap.php';

$rtdb = brisko_rtdb();
$config = $rtdb->get('loyaltyConfig');
$days = is_array($config) ? (int) ($config['pointsExpiryDays'] ?? 90) : 90;
$cutoff = brisko_now_ms() - ($days * 86400000);
$users = brisko_map($rtdb->get('users'));
$expiredUsers = 0;

foreach ($users as $uid => $user) {
    if (!is_array($user)) {
        continue;
    }
    $history = $user['loyaltyHistory'] ?? [];
    if (!is_array($history) || $history === []) {
        continue;
    }
    $points = (int) ($user['loyaltyPoints'] ?? 0);
    if ($points <= 0) {
        continue;
    }
    $earned = 0;
    $redeemed = 0;
    foreach ($history as $row) {
        if (!is_array($row)) {
            continue;
        }
        $created = (int) ($row['createdAt'] ?? 0);
        if ($created >= $cutoff) {
            $earned += (int) ($row['pointsEarned'] ?? 0);
            $redeemed += (int) ($row['pointsRedeemed'] ?? 0);
        }
    }
    $keep = max(0, $earned - $redeemed);
    if ($keep < $points) {
        $rtdb->patch('users/' . $uid, ['loyaltyPoints' => $keep]);
        $rtdb->put('users/' . $uid . '/loyaltyHistory/exp' . brisko_now_ms(), [
            'orderId' => null,
            'pointsEarned' => 0,
            'pointsRedeemed' => $points - $keep,
            'balanceAfter' => $keep,
            'createdAt' => brisko_now_ms(),
        ]);
        $expiredUsers++;
    }
}

echo json_encode(['ok' => true, 'expiredUsers' => $expiredUsers]);
