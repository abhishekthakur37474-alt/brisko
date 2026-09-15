<?php

declare(strict_types=1);

require_once __DIR__ . '/../services/firebase_service.php';

/**
 * Authentication guard for authenticated, server-controlled endpoints.
 *
 * The Flutter app sends the Firebase ID token of the signed-in user as
 * `Authorization: Bearer <idToken>`. The UID is taken from the verified token,
 * never from a client-supplied field.
 */

if (!function_exists('bearer_token')) {
    function bearer_token(): ?string
    {
        $header = $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? '';

        if ($header === '' && function_exists('getallheaders')) {
            $headers = getallheaders();
            if (is_array($headers)) {
                foreach ($headers as $key => $value) {
                    if (strtolower((string) $key) === 'authorization') {
                        $header = (string) $value;
                        break;
                    }
                }
            }
        }

        if (!preg_match('/^Bearer\s+(.+)$/i', trim((string) $header), $matches)) {
            return null;
        }

        $token = trim($matches[1]);
        return $token !== '' ? $token : null;
    }
}

if (!function_exists('require_firebase_uid')) {
    /**
     * Returns the authenticated user's Firebase UID or throws a 401.
     */
    function require_firebase_uid(): string
    {
        $token = bearer_token();
        if ($token === null) {
            throw new ApiException('Please sign in to continue.', 401);
        }
        return firebase_service()->verifyIdToken($token);
    }
}
