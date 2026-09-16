<?php

declare(strict_types=1);

/**
 * DISABLED: The Cashfree integration was replaced by UPI Intent payments.
 * This service is kept for reference only and is no longer wired into any
 * endpoint (see api/cashfree/*, which now return 410 Gone).
 *
 * Centralised Cashfree Payment Gateway client.
 *
 * Credentials and the API base URL live here only — they must never be copied
 * into individual endpoints, Flutter or Firebase. The base URL is derived from
 * the configured environment so Sandbox and Production can never be mixed:
 *
 *   SANDBOX    -> https://sandbox.cashfree.com/pg
 *   PRODUCTION -> https://api.cashfree.com/pg
 *
 * All calls use the current Orders API (x-api-version header, defaults to
 * 2025-01-01) exactly as documented at
 * https://www.cashfree.com/docs/api-reference/payments/latest/orders/create-order
 */
class CashfreeService
{
    private string $clientId;
    private string $clientSecret;
    private string $baseUrl;
    private string $apiVersion;
    private int $timeout;

    /** @param array<string, mixed> $config */
    public function __construct(array $config)
    {
        $this->clientId = trim((string) ($config['client_id'] ?? ''));
        $this->clientSecret = trim((string) ($config['client_secret'] ?? ''));

        $environment = strtoupper(trim((string) ($config['environment'] ?? 'SANDBOX')));
        $this->baseUrl = $environment === 'PRODUCTION'
            ? 'https://api.cashfree.com/pg'
            : 'https://sandbox.cashfree.com/pg';

        $this->apiVersion = trim((string) ($config['api_version'] ?? '2025-01-01'));
        if ($this->apiVersion === '') {
            $this->apiVersion = '2025-01-01';
        }

        $this->timeout = max(5, (int) ($config['timeout'] ?? 20));
    }

    public function isConfigured(): bool
    {
        return $this->clientId !== '' && $this->clientSecret !== '';
    }

    private function assertConfigured(): void
    {
        if (!$this->isConfigured()) {
            throw new ApiException('Online payment is not configured right now. Please try again later.', 503);
        }
    }

    /** @param array<string, mixed> $order */
    public function createOrder(array $order): array
    {
        $this->assertConfigured();
        return $this->request('POST', '/orders', $order);
    }

    public function getOrder(string $orderId): array
    {
        $this->assertConfigured();
        return $this->request('GET', '/orders/' . rawurlencode($orderId));
    }

    /** @return array<int, array<string, mixed>> */
    public function getOrderPayments(string $orderId): array
    {
        $this->assertConfigured();
        $response = $this->request('GET', '/orders/' . rawurlencode($orderId) . '/payments');
        return array_values(array_filter($response, 'is_array'));
    }

    /**
     * Verifies a Cashfree webhook signature.
     *
     * Cashfree signs `timestamp + rawBody` with HMAC-SHA256 using the client
     * secret and Base64-encodes the digest. The raw (unparsed) body must be
     * used. See https://www.cashfree.com/docs/payments/online/webhooks/signature-verification
     */
    public function verifyWebhookSignature(string $rawBody, string $signature, string $timestamp): bool
    {
        if ($signature === '' || $timestamp === '' || $this->clientSecret === '') {
            return false;
        }

        $expected = base64_encode(hash_hmac('sha256', $timestamp . $rawBody, $this->clientSecret, true));
        return hash_equals($expected, $signature);
    }

    /**
     * @param array<string, mixed>|null $body
     * @return array<string, mixed>
     */
    private function request(string $method, string $path, ?array $body = null): array
    {
        $url = rtrim($this->baseUrl, '/') . $path;

        $headers = [
            'Content-Type: application/json',
            'Accept: application/json',
            'x-client-id: ' . $this->clientId,
            'x-client-secret: ' . $this->clientSecret,
            'x-api-version: ' . $this->apiVersion,
        ];

        $ch = curl_init($url);
        if ($ch === false) {
            throw new ApiException('Unable to reach the payment gateway. Please try again.', 502);
        }

        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_TIMEOUT => $this->timeout,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
        ]);

        if ($body !== null) {
            curl_setopt(
                $ch,
                CURLOPT_POSTFIELDS,
                json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
            );
        }

        $raw = curl_exec($ch);
        $errno = curl_errno($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($errno !== 0 || $raw === false) {
            error_log('[brisko] cashfree network error: ' . $curlError . ' (errno=' . $errno . ')');
            throw new ApiException('Unable to reach the payment gateway. Please try again.', 502);
        }

        $decoded = json_decode((string) $raw, true);

        if ($status < 200 || $status >= 300) {
            $message = is_array($decoded) ? (string) ($decoded['message'] ?? '') : '';
            $code = is_array($decoded) ? (string) ($decoded['code'] ?? '') : '';
            error_log(sprintf(
                '[brisko] cashfree api error status=%d code=%s message=%s',
                $status,
                $code,
                $message
            ));
            // Never leak the raw gateway message to the client.
            throw new ApiException(
                'Unable to process the payment right now. Please try again.',
                $status >= 500 ? 502 : 400
            );
        }

        return is_array($decoded) ? $decoded : [];
    }
}
