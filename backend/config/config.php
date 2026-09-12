<?php

return [
    'rtdb_base_url' => 'https://brisko-20395-default-rtdb.asia-southeast1.firebasedatabase.app',
    'service_account_file' => __DIR__ . '/firebase-service-account.json',
    'fast2sms_api_key' => '3hvpx6XGSuJRlZwEdrtKcF82jg5HmWMD4fQaNqCIbBs9VkYnoAwdMUH9e6IG1K4vh7BTPc2okq8gsiQt',
    'fast2sms_sender_id' => 'BRISKO',
    'otp_length' => 6,
    'otp_ttl_seconds' => 300,
    'otp_resend_cooldown_seconds' => 60,
    'otp_max_sends_per_hour' => 5,
    'otp_max_verify_attempts' => 5,
    'otp_dev_echo' => false, // Live / Production setup ke liye false
];  