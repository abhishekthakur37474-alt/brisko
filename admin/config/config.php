<?php

declare(strict_types=1);

return [
    'rtdb_base_url' => getenv('BRISKO_RTDB_URL') ?: 'https://brisko-20395-default-rtdb.asia-southeast1.firebasedatabase.app',
    'service_account_file' => __DIR__ . '/firebase-service-account.json',
    'imgbb_api_key' => getenv('BRISKO_IMGBB_KEY') ?: '66078ac1ded9c8184ec8c35bd8b9dc7a',
    'fcm_project_id' => 'brisko-20395',
    'session_name' => 'brisko_admin',
    'login_max_attempts' => 8,
    'login_lock_seconds' => 900,
    'invoice_dir' => rtrim(getenv('BRISKO_INVOICE_DIR') ?: dirname(__DIR__, 2) . '/invoices', '/'),
    'invoice_base_url' => rtrim(getenv('BRISKO_INVOICE_BASE_URL') ?: 'https://briskopizza.com', '/'),
    'attempts_dir' => dirname(__DIR__) . '/storage/attempts',
];
