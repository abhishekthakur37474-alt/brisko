<?php

declare(strict_types=1);

use Kreait\Firebase\Contract\Auth as FirebaseAuthContract;
use Kreait\Firebase\Contract\Database;
use Kreait\Firebase\Database\Reference;
use Kreait\Firebase\Factory;

/**
 * Thin, read/write wrapper around the Firebase Admin SDK for the Cashfree flow.
 *
 * It reuses the exact same service account the OTP backend already uses
 * (FIREBASE_SERVICE_ACCOUNT_PATH) so there is no second Firebase project and no
 * extra credential. It can:
 *   - verify a Firebase ID token sent by Flutter and return the authenticated UID
 *   - read/write Firebase Realtime Database nodes (orders, coupons, users, ...)
 *
 * The Admin SDK bypasses RTDB security rules, which is why it is the only
 * component allowed to change payment fields.
 */
class FirebaseService
{
    private FirebaseAuthContract $auth;
    private ?Database $database = null;

    /** @param array<string, mixed> $config */
    public function __construct(array $config)
    {
        $path = (string) ($config['service_account_path'] ?? '');
        if ($path === '' || !is_file($path)) {
            throw new ApiException('Authentication service is not configured.', 500);
        }

        $factory = (new Factory())->withServiceAccount($path);
        if (!empty($config['project_id'])) {
            $factory = $factory->withProjectId((string) $config['project_id']);
        }

        $this->auth = $factory->createAuth();

        if (!empty($config['database_url'])) {
            $this->database = $factory->withDatabaseUri((string) $config['database_url'])->createDatabase();
        }
    }

    public function database(): Database
    {
        if ($this->database === null) {
            throw new ApiException('Database service is not configured.', 500);
        }
        return $this->database;
    }

    public function ref(string $path): Reference
    {
        return $this->database()->getReference($path);
    }

    /** Read a node and return it as-is (array, scalar or null). */
    public function get(string $path): mixed
    {
        return $this->ref($path)->getValue();
    }

    /**
     * Verifies a Firebase ID token (from the Authorization: Bearer header) and
     * returns the authenticated user's UID.
     */
    public function verifyIdToken(string $idToken): string
    {
        try {
            $token = $this->auth->verifyIdToken($idToken);
        } catch (\Throwable $e) {
            error_log('[brisko] firebase id token verification failed: ' . $e->getMessage());
            throw new ApiException('Your session has expired. Please sign in again.', 401);
        }

        $uid = (string) $token->claims()->get('sub');
        if ($uid === '') {
            throw new ApiException('Your session has expired. Please sign in again.', 401);
        }

        return $uid;
    }
}

if (!function_exists('firebase_service')) {
    /**
     * Shared FirebaseService instance, configured from the existing Firebase
     * Admin SDK settings (no second project, no second credential).
     */
    function firebase_service(): FirebaseService
    {
        static $service = null;
        if ($service === null) {
            $service = new FirebaseService(brisko_config()['firebase']);
        }
        return $service;
    }
}
