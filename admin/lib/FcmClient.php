<?php

declare(strict_types=1);

class FcmClient
{
    private array $config;
    private ?string $token = null;

    public function __construct(array $config)
    {
        $this->config = $config;
    }

    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): int
    {
        $tokens = array_values(array_unique(array_filter($tokens, static fn ($t) => is_string($t) && $t !== '')));
        if ($tokens === []) {
            return 0;
        }
        $access = $this->accessToken();
        if (!$access) {
            return 0;
        }
        $project = (string) ($this->config['fcm_project_id'] ?? 'brisko-20395');
        $sent = 0;
        foreach ($tokens as $token) {
            $payload = [
                'message' => [
                    'token' => $token,
                    'notification' => ['title' => $title, 'body' => $body],
                    'data' => array_map('strval', $data),
                    'android' => ['priority' => 'HIGH'],
                ],
            ];
            $ch = curl_init('https://fcm.googleapis.com/v1/projects/' . rawurlencode($project) . '/messages:send');
            curl_setopt_array($ch, [
                CURLOPT_POST => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 15,
                CURLOPT_HTTPHEADER => [
                    'Authorization: Bearer ' . $access,
                    'Content-Type: application/json',
                ],
                CURLOPT_POSTFIELDS => json_encode($payload),
            ]);
            $raw = curl_exec($ch);
            $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($code >= 200 && $code < 300) {
                $sent++;
            }
            unset($raw);
        }
        return $sent;
    }

    private function accessToken(): ?string
    {
        if ($this->token) {
            return $this->token;
        }
        $file = $this->config['service_account_file'] ?? '';
        if (!is_file($file)) {
            return null;
        }
        $sa = json_decode((string) file_get_contents($file), true);
        if (!$sa || empty($sa['private_key']) || empty($sa['client_email'])) {
            return null;
        }
        $now = time();
        $header = rtrim(strtr(base64_encode((string) json_encode(['alg' => 'RS256', 'typ' => 'JWT'])), '+/', '-_'), '=');
        $claim = rtrim(strtr(base64_encode((string) json_encode([
            'iss' => $sa['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ])), '+/', '-_'), '=');
        $unsigned = $header . '.' . $claim;
        $ok = openssl_sign($unsigned, $signature, $sa['private_key'], 'SHA256');
        if (!$ok) {
            return null;
        }
        $jwt = $unsigned . '.' . rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_TIMEOUT => 20,
            CURLOPT_POSTFIELDS => http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]),
        ]);
        $res = json_decode((string) curl_exec($ch), true);
        curl_close($ch);
        $this->token = $res['access_token'] ?? null;
        return $this->token;
    }
}
