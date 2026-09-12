<?php

declare(strict_types=1);

class Fast2SmsClient
{
    private array $config;

    public function __construct(array $config)
    {
        $this->config = $config;
    }

    public function sendOtp(string $normalizedPhone, string $otp): void
    {
        $key = trim((string) ($this->config['fast2sms_api_key'] ?? ''));
        if ($key === '' || $key === 'YOUR_FAST2SMS_API_KEY') {
            if (!empty($this->config['otp_dev_echo'])) {
                return;
            }
            throw new RuntimeException('Fast2SMS API key is not configured.');
        }

        $number = Phone::national($normalizedPhone);
        $ch = curl_init('https://www.fast2sms.com/dev/bulkV2');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_TIMEOUT => 20,
            CURLOPT_HTTPHEADER => [
                'authorization: ' . $key,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS => json_encode([
                'route' => 'otp',
                'variables_values' => $otp,
                'numbers' => $number,
                'flash' => 0,
            ]),
        ]);
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);
        if ($raw === false) {
            throw new RuntimeException('Fast2SMS request failed: ' . $err);
        }
        $res = json_decode((string) $raw, true);
        if ($code >= 400 || empty($res['return'])) {
            $msg = is_array($res) ? ($res['message'] ?? $raw) : $raw;
            if (is_array($msg)) {
                $msg = implode(', ', $msg);
            }
            throw new RuntimeException('Fast2SMS error: ' . $msg);
        }
    }
}
