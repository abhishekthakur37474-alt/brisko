<?php

declare(strict_types=1);

/**
 * Sliding-window rate limiting for OTP sends, keyed by mobile number.
 *
 * This is an additional guard on top of the provider's own limit: never rely
 * solely on ApiTxt's "3 OTP requests / minute" ceiling.
 */

if (!function_exists('rate_limit_file_for')) {
    function rate_limit_file_for(string $mobile): string
    {
        $dir = otp_storage_dir() . '/rate';
        if (!is_dir($dir)) {
            @mkdir($dir, 0770, true);
        }
        return $dir . '/' . hash('sha256', $mobile) . '.json';
    }
}

if (!function_exists('rate_limit_allow')) {
    /**
     * Returns true and records the attempt when under `$limit` within
     * `$windowSeconds`; returns false when the limit is exceeded.
     */
    function rate_limit_allow(string $mobile, int $limit, int $windowSeconds): bool
    {
        if ($limit <= 0) {
            return true;
        }

        $file = rate_limit_file_for($mobile);
        $now = time();
        $events = [];
        if (is_file($file)) {
            $decoded = json_decode((string) @file_get_contents($file), true);
            if (is_array($decoded)) {
                $events = array_values(array_filter(
                    array_map('intval', $decoded),
                    static fn (int $ts): bool => ($now - $ts) < $windowSeconds
                ));
            }
        }

        if (count($events) >= $limit) {
            return false;
        }

        $events[] = $now;
        @file_put_contents($file, json_encode($events), LOCK_EX);
        @chmod($file, 0660);
        return true;
    }
}
