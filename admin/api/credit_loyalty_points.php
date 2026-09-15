<?php

declare(strict_types=1);

function brisko_credit_loyalty(RtdbClient $rtdb, string $orderId, array $order): void
{
    if (($order['loyaltyCredited'] ?? false) === true) {
        return;
    }
    $uid = (string) ($order['userId'] ?? '');
    if ($uid === '') {
        return;
    }
    $config = $rtdb->get('loyaltyConfig');
    $rate = is_array($config) ? (float) ($config['pointsPerRupeeSpent'] ?? 0.05) : 0.05;
    $minOrderValue = is_array($config) ? (float) ($config['minOrderValueForPoints'] ?? 0) : 0;
    $amount = (float) ($order['finalAmount'] ?? 0);
    if ($amount < $minOrderValue) {
        $rtdb->patch('orders/' . $orderId, ['loyaltyCredited' => true]);
        return;
    }
    $earned = (int) floor($amount * $rate);
    if ($earned <= 0) {
        $rtdb->patch('orders/' . $orderId, ['loyaltyCredited' => true]);
        return;
    }
    $user = $rtdb->get('users/' . $uid);
    $current = is_array($user) ? (int) ($user['loyaltyPoints'] ?? 0) : 0;
    $balance = $current + $earned;
    $now = (int) round(microtime(true) * 1000);
    $entryId = 'l' . $now;
    $rtdb->patch('users/' . $uid, ['loyaltyPoints' => $balance]);
    $rtdb->put('users/' . $uid . '/loyaltyHistory/' . $entryId, [
        'orderId' => $orderId,
        'pointsEarned' => $earned,
        'pointsRedeemed' => 0,
        'balanceAfter' => $balance,
        'createdAt' => $now,
    ]);
    $rtdb->patch('orders/' . $orderId, ['loyaltyCredited' => true]);
}
