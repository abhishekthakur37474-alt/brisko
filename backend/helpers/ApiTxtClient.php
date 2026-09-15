<?php

declare(strict_types=1);

/**
 * Thin ApiTxt Unified OTP API client.
 *
 * The auth key never leaves this server. `template_id` is intentionally
 * optional: when omitted, ApiTxt falls back to the account's default SMS OTP
 * configuration. No DLT/template logic is hard-coded here.
 */
class ApiTxtClient
{
    /** @param array<string, mixed> $config */
    public function __construct(private array $config)
    {
    }

    /**
     * @return array{request_id: ?string}
     */
    public function sendOtp(string $mobile, string $otp): array
    {
        $authKey = trim((string) ($this->config['auth_key'] ?? ''));
        if ($authKey === '') {
            throw new ApiException('OTP service is not configured.', 500);
        }

        $fields = [
            'authkey' => $authKey,
            'mobile' => $mobile,
            'otp' => $otp,
            'channel' => ($this->config['channel'] ?? '') !== '' ? $this->config['channel'] : 'sms',
        ];
        foreach (['template_id', 'template_name', 'country'] as $optional) {
            $value = trim((string) ($this->config[$optional] ?? ''));
            if ($value !== '') {
                $fields[$optional] = $value;
            }
        }

        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => (string) $this->config['endpoint'],
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => http_build_query($fields),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => (int) ($this->config['timeout'] ?? 20),
            CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
        ]);

        $body = curl_exec($ch);
        $httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($body === false) {
            error_log('[brisko] apitxt curl error: ' . $curlError);
            throw new ApiException('Unable to send OTP right now. Please try again.', 502);
        }

        $decoded = json_decode((string) $body, true);
        $status = is_array($decoded) ? strtolower((string) ($decoded['status'] ?? '')) : '';

        if ($httpCode < 200 || $httpCode >= 300 || $status !== 'success') {
            // Never log the OTP; only the transport-level outcome.
            error_log('[brisko] apitxt send failed http=' . $httpCode . ' status=' . ($status !== '' ? $status : 'unknown'));
            throw new ApiException('Unable to send OTP right now. Please try again.', 502);
        }

        $requestId = null;
        if (is_array($decoded) && isset($decoded['data']) && is_array($decoded['data'])) {
            $requestId = $decoded['data']['request_id'] ?? null;
        }

        return ['request_id' => is_string($requestId) ? $requestId : null];
    }
}
