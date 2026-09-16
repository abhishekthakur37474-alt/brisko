<?php

declare(strict_types=1);

/**
 * Brisko Pizza OTP backend configuration.
 *
 * Secrets are read from environment variables (preferred) or from an optional
 * `.env` file that lives in this folder and is never committed. Copy
 * `.env.example` to `.env` and fill in real values.
 *
 * The ApiTxt auth key and the Firebase service account must only ever exist on
 * this server. Never ship them inside the Flutter app.
 */

// Optional local overrides (git-ignored). Kept as `require_once` so both this
// file and any entry point can trigger it safely.
if (is_file(__DIR__ . '/config.local.php')) {
    require_once __DIR__ . '/config.local.php';
}

// Allow a small .env file to populate getenv() if the host does not provide one.
if (is_file(__DIR__ . '/.env')) {
    $lines = file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || $line[0] === '#' || !str_contains($line, '=')) {
            continue;
        }
        [$k, $v] = explode('=', $line, 2);
        $k = trim($k);  
        $v = trim($v, " \t\"'");
        if ($k !== '' && getenv($k) === false) {
            putenv($k . '=' . $v);
        }
    }
}

if (!function_exists('env_value')) {
    function env_value(string $key, ?string $default = null): ?string
    {
        $value = getenv($key);
        if ($value === false || $value === '') {
            return $default;
        }
        return $value;
    }
}

if (!function_exists('env_bool')) {
    function env_bool(string $key, bool $default = false): bool
    {
        $value = getenv($key);
        if ($value === false || $value === '') {
            return $default;
        }
        return filter_var($value, FILTER_VALIDATE_BOOLEAN);
    }
}

if (!function_exists('env_list')) {
    /** @return list<string> */
    function env_list(string $key): array
    {
        $value = trim((string) env_value($key, ''));
        if ($value === '') {
            return [];
        }
        return array_values(array_filter(array_map('trim', explode(',', $value))));
    }
}

if (!function_exists('brisko_config')) {
    function brisko_config(): array
    {
        static $config = null;
        if ($config !== null) {
            return $config;
        }

        $backendRoot = dirname(__DIR__);

        $config = [
            'apitxt' => [
                'endpoint' => env_value('APITXT_ENDPOINT', 'https://apitxt.com/api/sendOTP'),
                'auth_key' => env_value('APITXT_AUTH_KEY', ''),
                'channel' => env_value('APITXT_CHANNEL', 'sms'),
                // Optional. When empty, ApiTxt uses its default SMS OTP config.
                'template_id' => env_value('APITXT_TEMPLATE_ID', ''),
                'template_name' => env_value('APITXT_TEMPLATE_NAME', ''),
                'country' => env_value('APITXT_COUNTRY', ''),
                'timeout' => (int) env_value('APITXT_TIMEOUT', '20'),
            ],
            'firebase' => [
                'service_account_path' => env_value(
                    'FIREBASE_SERVICE_ACCOUNT_PATH',
                    __DIR__ . '/firebase-service-account.json'
                ),
                'project_id' => env_value('FIREBASE_PROJECT_ID', ''),
                // Brisko keeps uid = normalized phone (deliberate, see project spec)
                // so RTDB rules can stay simple. Set false to let Firebase assign.
                'use_phone_as_uid' => env_bool('FIREBASE_PHONE_AS_UID', true),
                // Optional: enables the PHP side to also seed the RTDB user record.
                'database_url' => env_value('FIREBASE_DATABASE_URL', ''),
            ],
            // DISABLED: Cashfree was replaced by UPI Intent payments. Kept for
            // reference; no endpoint reads this block anymore.
            'cashfree' => [
                // Server-side only. NEVER expose these to Flutter or Firebase.
                'client_id' => env_value('CASHFREE_CLIENT_ID', ''),
                'client_secret' => env_value('CASHFREE_CLIENT_SECRET', ''),
                // SANDBOX or PRODUCTION. The API base URL is derived from this.
                'environment' => strtoupper((string) env_value('CASHFREE_ENVIRONMENT', 'SANDBOX')),
                'api_version' => env_value('CASHFREE_API_VERSION', '2025-01-01'),
                'timeout' => (int) env_value('CASHFREE_TIMEOUT', '20'),
                // Optional. When set, used as order_meta.return_url on the order.
                'return_url' => env_value('CASHFREE_RETURN_URL', ''),
                'allowed_currencies' => env_list('CASHFREE_ALLOWED_CURRENCIES') ?: ['INR'],
            ],
            // UPI Intent payments. The merchant VPA is a public payee address
            // (not a secret) that the app builds the `upi://pay` intent from; it
            // is mirrored here so the server can log/reconcile the destination.
            'upi' => [
                'merchant_vpa' => env_value('UPI_MERCHANT_VPA', ''),
                'merchant_name' => env_value('UPI_MERCHANT_NAME', 'Brisko Pizza'),
                // Optional server-side verifier. When set, the backend POSTs the
                // UPI txn details to this URL and only flips the order to `paid`
                // when the verifier returns {"verified": true}. When empty, orders
                // stay pending until an admin reconciles them manually.
                'verify_url' => env_value('UPI_VERIFY_URL', ''),
                'verify_secret' => env_value('UPI_VERIFY_SECRET', ''),
                'verify_timeout' => (int) env_value('UPI_VERIFY_TIMEOUT', '15'),
            ],
            // Server-authoritative pricing. Must mirror the Flutter pricing so the
            // amount paid is always the amount the server computed from the catalog.
            'pricing' => [
                'gst_rate' => (float) env_value('BRISKO_GST_RATE', '0.05'),
                'free_delivery_threshold' => (float) env_value('BRISKO_FREE_DELIVERY_THRESHOLD', '499'),
                'flat_delivery_fee' => (float) env_value('BRISKO_FLAT_DELIVERY_FEE', '40'),
                'max_order_amount' => (float) env_value('BRISKO_MAX_ORDER_AMOUNT', '50000'),
            ],
            'otp' => [
                'expiry_seconds' => (int) env_value('OTP_EXPIRY_SECONDS', '300'),
                'max_attempts' => (int) env_value('OTP_MAX_ATTEMPTS', '5'),
                'resend_cooldown' => (int) env_value('OTP_RESEND_COOLDOWN', '30'),
                'rate_per_minute' => (int) env_value('OTP_RATE_PER_MINUTE', '3'),
                'rate_per_hour' => (int) env_value('OTP_RATE_PER_HOUR', '10'),
            ],
            'storage' => [
                'path' => env_value('OTP_STORAGE_PATH', $backendRoot . '/storage/otp'),
                'log' => env_value('BRISKO_LOG_PATH', $backendRoot . '/storage/logs/app.log'),
            ],
            'cors' => [
                'allowed_origins' => env_list('CORS_ALLOWED_ORIGINS'),
            ],
            'debug' => env_bool('APP_DEBUG', false),
        ];

        return $config;
    }
}
