<?php

declare(strict_types=1);

/**
 * Shared OTP generation + delivery flow used by both send-otp.php and
 * resend-otp.php. Enforces provider-independent rate limits and invalidates any
 * previous OTP for the same mobile.
 */

require_once __DIR__ . '/otp_store.php';
require_once __DIR__ . '/rate_limit.php';
require_once __DIR__ . '/ApiTxtClient.php';
require_once __DIR__ . '/validation.php';

if (!function_exists('otp_generate_and_send')) {
    /**
     * @param array<string, mixed> $config
     * @return array{request_id: ?string}
     */
    function otp_generate_and_send(string $mobile, array $config, bool $isResend): array
    {
        $otpCfg = $config['otp'];

        if (!rate_limit_allow($mobile, (int) $otpCfg['rate_per_minute'], 60)) {
            throw new ApiException('Too many OTP requests. Please wait a minute and try again.', 429);
        }
        if (!rate_limit_allow($mobile, (int) $otpCfg['rate_per_hour'], 3600)) {
            throw new ApiException('Too many OTP requests. Please try again later.', 429);
        }

        $existing = otp_read($mobile);
        if ($existing !== null && isset($existing['last_sent_at'])) {
            $elapsed = time() - (int) $existing['last_sent_at'];
            if ($elapsed < (int) $otpCfg['resend_cooldown']) {
                $wait = (int) $otpCfg['resend_cooldown'] - $elapsed;
                throw new ApiException('Please wait ' . $wait . 's before requesting another OTP.', 429);
            }
        }

        // Cryptographically secure, server-side only.
        $otp = (string) random_int(100000, 999999);
        $now = time();

        $record = [
            'id' => bin2hex(random_bytes(8)),
            'mobile' => $mobile,
            'otp_hash' => password_hash($otp, PASSWORD_DEFAULT),
            'created_at' => $now,
            'expires_at' => $now + (int) $otpCfg['expiry_seconds'],
            'attempt_count' => 0,
            'verified' => false,
            'request_id' => null,
            'last_sent_at' => $now,
        ];
        // Overwrites (invalidates) any previous OTP for this mobile.
        otp_write($mobile, $record);

        try {
            $client = new ApiTxtClient($config['apitxt']);
            $result = $client->sendOtp($mobile, $otp);
        } catch (Throwable $e) {
            // Do not leave a dead OTP behind for a send that never went out.
            otp_delete($mobile);
            throw $e;
        }

        $record['request_id'] = $result['request_id'];
        otp_write($mobile, $record);

        error_log(sprintf(
            '[brisko] otp %s mobile=%s request_id=%s',
            $isResend ? 'resent' : 'sent',
            mask_mobile($mobile),
            $result['request_id'] ?? 'n/a'
        ));

        return ['request_id' => $result['request_id'] ?? null];
    }
}
