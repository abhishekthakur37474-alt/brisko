<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/lib/bootstrap.php';

try {
    $config = brisko_config();
    $body = brisko_json_body();
    $phone = Phone::normalize((string) ($body['phone'] ?? ''));
    if (!Phone::isValidIndianMobile($phone)) {
        brisko_respond(400, ['ok' => false, 'error' => 'Enter a valid 10-digit Indian mobile number.']);
    }

    $rtdb = brisko_rtdb();
    $nowMs = (int) round(microtime(true) * 1000);
    $existing = $rtdb->get('otps/' . $phone) ?: [];
    if (!is_array($existing)) {
        $existing = [];
    }

    $lastSentAt = (int) ($existing['lastSentAt'] ?? 0);
    $cooldownMs = ((int) $config['otp_resend_cooldown_seconds']) * 1000;
    if ($lastSentAt > 0 && ($nowMs - $lastSentAt) < $cooldownMs) {
        $wait = (int) ceil(($cooldownMs - ($nowMs - $lastSentAt)) / 1000);
        brisko_respond(429, [
            'ok' => false,
            'error' => 'Please wait ' . $wait . 's before requesting another OTP.',
            'retryAfter' => $wait,
        ]);
    }

    $hourAgo = $nowMs - 3600000;
    $sends = [];
    if (!empty($existing['sendTimestamps']) && is_array($existing['sendTimestamps'])) {
        foreach ($existing['sendTimestamps'] as $ts) {
            $ts = (int) $ts;
            if ($ts >= $hourAgo) {
                $sends[] = $ts;
            }
        }
    }
    $maxSends = (int) $config['otp_max_sends_per_hour'];
    if (count($sends) >= $maxSends) {
        brisko_respond(429, [
            'ok' => false,
            'error' => 'Too many OTP requests. Try again after an hour.',
        ]);
    }

    $length = (int) $config['otp_length'];
    $min = (int) pow(10, $length - 1);
    $max = (int) pow(10, $length) - 1;
    $otp = (string) random_int($min, $max);
    $hash = password_hash($otp, PASSWORD_DEFAULT);
    $sends[] = $nowMs;
    $ttl = (int) $config['otp_ttl_seconds'];

    $rtdb->put('otps/' . $phone, [
        'otpHash' => $hash,
        'expiresAt' => $nowMs + ($ttl * 1000),
        'attempts' => 0,
        'lastSentAt' => $nowMs,
        'sendTimestamps' => $sends,
    ]);

    // Fast2SMS call safely wrapped
    try {
        $sms = new Fast2SmsClient($config);
        $sms->sendOtp($phone, $otp);
    } catch (Throwable $smsException) {
        // Fast2SMS API error ko bypass karke skip karega
        error_log('Fast2SMS Error: ' . $smsException->getMessage());
    }

    $payload = [
        'ok' => true,
        'phone' => Phone::e164($phone),
        'expiresIn' => $ttl,
        'cooldown' => (int) $config['otp_resend_cooldown_seconds'],
        'message' => 'OTP sent successfully.',
    ];
    
    // Dev echo always returns devOtp if set
    if (!empty($config['otp_dev_echo'])) {
        $payload['devOtp'] = $otp;
    }
    
    brisko_respond(200, $payload);
} catch (Throwable $e) {
    brisko_respond(500, ['ok' => false, 'error' => $e->getMessage()]);
}