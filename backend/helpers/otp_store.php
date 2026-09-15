<?php

declare(strict_types=1);

/**
 * Temporary, server-side OTP storage.
 *
 * Records are keyed by mobile number and hold a hashed OTP only — the plain
 * OTP is never persisted. A new OTP for a mobile always overwrites the old
 * record, so requesting/resending automatically invalidates the previous code.
 *
 * This file-backed store works out of the box. Swap the four `otp_*` functions
 * for PDO/MySQL queries if a database is available; the rest of the codebase
 * only depends on this interface.
 */

if (!function_exists('otp_storage_dir')) {
    function otp_storage_dir(): string
    {
        $config = brisko_config();
        $dir = $config['storage']['path'];
        if (!is_dir($dir)) {
            @mkdir($dir, 0770, true);
        }
        return $dir;
    }
}

if (!function_exists('otp_file_for')) {
    function otp_file_for(string $mobile): string
    {
        return otp_storage_dir() . '/' . hash('sha256', $mobile) . '.json';
    }
}

if (!function_exists('otp_read')) {
    /** @return array<string, mixed>|null */
    function otp_read(string $mobile): ?array
    {
        $file = otp_file_for($mobile);
        if (!is_file($file)) {
            return null;
        }
        $raw = @file_get_contents($file);
        if ($raw === false || $raw === '') {
            return null;
        }
        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            return null;
        }
        // Guard against a record copied to the wrong mobile.
        if (($decoded['mobile'] ?? null) !== $mobile) {
            return null;
        }
        return $decoded;
    }
}

if (!function_exists('otp_write')) {
    function otp_write(string $mobile, array $record): void
    {
        $record['mobile'] = $mobile;
        $file = otp_file_for($mobile);
        $tmp = $file . '.' . bin2hex(random_bytes(4)) . '.tmp';
        $json = json_encode($record, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($json === false) {
            throw new ApiException('Unable to process OTP right now. Please try again.', 500);
        }
        if (@file_put_contents($tmp, $json, LOCK_EX) === false) {
            @unlink($tmp);
            throw new ApiException('Unable to process OTP right now. Please try again.', 500);
        }
        @chmod($tmp, 0660);
        if (!@rename($tmp, $file)) {
            @unlink($tmp);
            throw new ApiException('Unable to process OTP right now. Please try again.', 500);
        }
    }
}

if (!function_exists('otp_delete')) {
    function otp_delete(string $mobile): void
    {
        $file = otp_file_for($mobile);
        if (is_file($file)) {
            @unlink($file);
        }
    }
}
