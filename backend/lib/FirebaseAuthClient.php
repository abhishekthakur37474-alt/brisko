<?php

declare(strict_types=1);

class FirebaseAuthClient
{
    private array $serviceAccount;

    public function __construct(array $config)
    {
        $file = $config['service_account_file'];
        if (!is_file($file)) {
            throw new RuntimeException('Firebase service account file is missing.');
        }
        $sa = json_decode((string) file_get_contents($file), true);
        if (!$sa || empty($sa['private_key']) || empty($sa['client_email'])) {
            throw new RuntimeException('Invalid Firebase service account JSON.');
        }
        $this->serviceAccount = $sa;
    }

    public function createCustomToken(string $uid, array $claims = []): string
    {
        if ($uid === '' || strlen($uid) > 128) {
            throw new InvalidArgumentException('Invalid uid for custom token.');
        }
        $now = time();
        $header = $this->b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = [
            'iss' => $this->serviceAccount['client_email'],
            'sub' => $this->serviceAccount['client_email'],
            'aud' => 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
            'iat' => $now,
            'exp' => $now + 3600,
            'uid' => $uid,
        ];
        if ($claims !== []) {
            $payload['claims'] = $claims;
        }
        $body = $this->b64(json_encode($payload));
        $unsigned = $header . '.' . $body;
        $ok = openssl_sign($unsigned, $signature, $this->serviceAccount['private_key'], 'SHA256');
        if (!$ok) {
            throw new RuntimeException('Failed to sign Firebase custom token.');
        }
        return $unsigned . '.' . $this->b64($signature);
    }

    private function b64(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
