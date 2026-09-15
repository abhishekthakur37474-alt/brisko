<?php

declare(strict_types=1);

/**
 * Mobile number normalization/validation.
 *
 * ApiTxt auto-prepends `91` for 10-digit numbers, but the backend normalizes
 * and validates explicitly so nothing malformed ever reaches the provider.
 */

if (!function_exists('normalize_mobile')) {
    /**
     * Returns the normalized `91XXXXXXXXXX` form, or null when invalid.
     */
    function normalize_mobile(string $raw): ?string
    {
        $digits = preg_replace('/\D+/', '', $raw) ?? '';
        if ($digits === '') {
            return null;
        }

        $digits = ltrim($digits, '0');

        if (strlen($digits) === 10) {
            $digits = '91' . $digits;
        }

        if (strlen($digits) === 12 && str_starts_with($digits, '91')) {
            $national = substr($digits, 2);
            if (preg_match('/^[6-9]\d{9}$/', $national) === 1) {
                return $digits;
            }
        }

        return null;
    }
}

if (!function_exists('normalize_otp')) {
    /**
     * Returns a 4-6 digit OTP string, or null when invalid.
     */
    function normalize_otp(string $raw): ?string
    {
        $trimmed = trim($raw);
        if (preg_match('/^\d{4,6}$/', $trimmed) === 1) {
            return $trimmed;
        }
        return null;
    }
}

if (!function_exists('mask_mobile')) {
    /**
     * Masks a mobile number for safe logging (e.g. 9198****10).
     */
    function mask_mobile(string $mobile): string
    {
        if (strlen($mobile) < 6) {
            return '***';
        }
        return substr($mobile, 0, 4) . '****' . substr($mobile, -2);
    }
}
