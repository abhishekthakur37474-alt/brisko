<?php

declare(strict_types=1);

class Phone
{
    public static function normalize(string $raw): string
    {
        $digits = preg_replace('/\D+/', '', $raw) ?? '';
        if (str_starts_with($digits, '0')) {
            $digits = ltrim($digits, '0');
        }
        if (strlen($digits) === 10) {
            $digits = '91' . $digits;
        }
        return $digits;
    }

    public static function isValidIndianMobile(string $normalized): bool
    {
        return (bool) preg_match('/^91[6-9]\d{9}$/', $normalized);
    }

    public static function national(string $normalized): string
    {
        return strlen($normalized) === 12 ? substr($normalized, 2) : $normalized;
    }

    public static function e164(string $normalized): string
    {
        return '+' . $normalized;
    }
}
