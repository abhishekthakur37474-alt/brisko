<?php

declare(strict_types=1);

class RtdbClient
{
    private array $config;
    private ?string $token = null;
    private bool $authAttempted = false;

    public function __construct(array $config)
    {
        $this->config = $config;
    }

    public function get(string $path)
    {
        return $this->request('GET', $path);
    }

    public function put(string $path, $data)
    {
        return $this->request('PUT', $path, $data);
    }

    public function patch(string $path, $data)
    {
        return $this->request('PATCH', $path, $data);
    }

    public function post(string $path, $data)
    {
        return $this->request('POST', $path, $data);
    }

    public function delete(string $path)
    {
        return $this->request('DELETE', $path);
    }

    public function hasServiceAccount(): bool
    {
        $file = $this->config['service_account_file'] ?? '';
        return is_string($file) && is_file($file);
    }

    private function request(string $method, string $path, $body = null)
    {
        $url = rtrim((string) $this->config['rtdb_base_url'], '/') . '/' . ltrim($path, '/') . '.json';
        $token = $this->accessToken();
        if ($token) {
            $url .= '?access_token=' . urlencode($token);
        }
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 25);
        $headers = ['Content-Type: application/json'];
        if ($body !== null) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
        }
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);
        if ($raw === false) {
            throw new RuntimeException('RTDB request failed: ' . $err);
        }
        if ($code >= 400) {
            throw new RuntimeException('RTDB error ' . $code . ': ' . $raw);
        }
        return json_decode($raw, true);
    }

    private function accessToken(): ?string
    {
        if ($this->authAttempted) {
            return $this->token;
        }
        $this->authAttempted = true;
        $file = $this->config['service_account_file'] ?? '';
        if (!is_file($file)) {
            return null;
        }
        $sa = json_decode((string) file_get_contents($file), true);
        if (!$sa || empty($sa['private_key']) || empty($sa['client_email'])) {
            return null;
        }
        $now = time();
        $header = $this->b64((string) json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $claim = $this->b64((string) json_encode([
            'iss' => $sa['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ]));
        $unsigned = $header . '.' . $claim;
        $ok = openssl_sign($unsigned, $signature, $sa['private_key'], 'SHA256');
        if (!$ok) {
            throw new RuntimeException('Failed to sign service-account JWT.');
        }
        $jwt = $unsigned . '.' . $this->b64($signature);
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

    private function b64(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
