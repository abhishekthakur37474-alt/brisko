<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/lib/bootstrap.php';

try {
    $config = brisko_config();
    $body = brisko_json_body();
    $phone = Phone::normalize((string) ($body['phone'] ?? ''));
    $otp = preg_replace('/\D+/', '', (string) ($body['otp'] ?? '')) ?? '';

    if (!Phone::isValidIndianMobile($phone)) {
        brisko_respond(400, ['ok' => false, 'error' => 'Enter a valid 10-digit Indian mobile number.']);
    }
    if (strlen($otp) < 4 || strlen($otp) > 8) {
        brisko_respond(400, ['ok' => false, 'error' => 'Enter the OTP sent to your phone.']);
    }

    $rtdb = brisko_rtdb();
    $nowMs = (int) round(microtime(true) * 1000);
    $record = $rtdb->get('otps/' . $phone);
    if (!is_array($record) || empty($record['otpHash'])) {
        brisko_respond(400, ['ok' => false, 'error' => 'OTP expired or not found. Request a new one.']);
    }

    $attempts = (int) ($record['attempts'] ?? 0);
    $maxAttempts = (int) $config['otp_max_verify_attempts'];
    if ($attempts >= $maxAttempts) {
        brisko_respond(429, ['ok' => false, 'error' => 'Too many incorrect attempts. Request a new OTP.']);
    }

    if ((int) ($record['expiresAt'] ?? 0) < $nowMs) {
        $rtdb->delete('otps/' . $phone);
        brisko_respond(400, ['ok' => false, 'error' => 'OTP expired. Request a new one.']);
    }

    if (!password_verify($otp, (string) $record['otpHash'])) {
        $rtdb->patch('otps/' . $phone, ['attempts' => $attempts + 1]);
        $left = max(0, $maxAttempts - $attempts - 1);
        brisko_respond(400, [
            'ok' => false,
            'error' => 'Incorrect OTP. ' . $left . ' attempt(s) left.',
        ]);
    }

    $action = (string) ($body['action'] ?? 'login');
    if ($action === 'verify_only') {
        $rtdb->delete('otps/' . $phone);
        brisko_respond(200, [
            'ok' => true,
            'phone' => Phone::e164($phone),
            'verified' => true,
        ]);
    }

    $uid = $phone;
    $existing = $rtdb->get('users/' . $uid);
    $isNewUser = !is_array($existing) || $existing === [];
    if ($isNewUser) {
        $profile = [
            'name' => '',
            'phone' => Phone::e164($phone),
            'email' => '',
            'createdAt' => $nowMs,
            'loyaltyPoints' => 0,
            'role' => 'customer',
            'fcmTokens' => new stdClass(),
        ];
        $rtdb->put('users/' . $uid, $profile);
    } else {
        $profile = $existing;
        if (empty($profile['phone'])) {
            $rtdb->patch('users/' . $uid, ['phone' => Phone::e164($phone)]);
            $profile['phone'] = Phone::e164($phone);
        }
    }

    $auth = new FirebaseAuthClient($config);
    $token = $auth->createCustomToken($uid);

    $rtdb->delete('otps/' . $phone);

    $name = trim((string) ($profile['name'] ?? ''));
    brisko_respond(200, [
        'ok' => true,
        'token' => $token,
        'uid' => $uid,
        'isNewUser' => $isNewUser || $name === '',
        'profile' => [
            'name' => $name,
            'phone' => $profile['phone'] ?? Phone::e164($phone),
            'email' => $profile['email'] ?? '',
            'role' => $profile['role'] ?? 'customer',
            'loyaltyPoints' => (int) ($profile['loyaltyPoints'] ?? 0),
        ],
    ]);
} catch (Throwable $e) {
    brisko_respond(500, ['ok' => false, 'error' => $e->getMessage()]);
}
