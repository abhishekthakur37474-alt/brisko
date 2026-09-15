<?php

declare(strict_types=1);

use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Kreait\Firebase\Contract\Database;
use Kreait\Firebase\Factory;

/**
 * Wraps the Firebase Admin SDK to (a) find-or-create the user for a verified
 * phone number, (b) mint custom sign-in tokens and (c) optionally seed the
 * Realtime Database user record.
 *
 * Service-account credentials live only on this server.
 */
class FirebaseAuthClient
{
    private FirebaseAuth $auth;
    private ?Database $database = null;
    private bool $usePhoneAsUid;

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
        $this->usePhoneAsUid = (bool) ($config['use_phone_as_uid'] ?? true);

        if (!empty($config['database_url'])) {
            $this->database = $factory->withDatabaseUri((string) $config['database_url'])->createDatabase();
        }
    }

    /**
     * @return array{uid: string, isNewUser: bool}
     */
    public function findOrCreateUserByPhone(string $mobile): array
    {
        $phone = '+' . $mobile;

        // 1) Preferred identity: uid == normalized phone (Brisko convention).
        if ($this->usePhoneAsUid) {
            try {
                $user = $this->auth->getUser($mobile);
                return ['uid' => $user->uid, 'isNewUser' => false];
            } catch (\Throwable $e) {
                // Not found (or lookup failed) — try phone lookup next.
            }
        }

        // 2) Look up by phone number for accounts created with a random uid.
        try {
            $user = $this->auth->getUserByPhoneNumber($phone);
            return ['uid' => $user->uid, 'isNewUser' => false];
        } catch (\Throwable $e) {
            // Not found — fall through to creation.
        }

        // 3) Create the Firebase user.
        $properties = ['phoneNumber' => $phone];
        if ($this->usePhoneAsUid) {
            $properties['uid'] = $mobile;
        }

        try {
            $user = $this->auth->createUser($properties);
            $isNew = true;
        } catch (\Throwable $e) {
            // Race: created elsewhere. Re-fetch by uid or phone.
            $user = null;
            if ($this->usePhoneAsUid) {
                try {
                    $user = $this->auth->getUser($mobile);
                } catch (\Throwable $inner) {
                    $user = null;
                }
            }
            if ($user === null) {
                try {
                    $user = $this->auth->getUserByPhoneNumber($phone);
                } catch (\Throwable $inner) {
                    error_log('[brisko] firebase create/get failed: ' . $inner->getMessage());
                    throw new ApiException('Authentication service is unavailable. Please try again.', 500);
                }
            }
            $isNew = false;
        }

        return ['uid' => $user->uid, 'isNewUser' => $isNew];
    }

    public function createCustomToken(string $uid): string
    {
        try {
            return $this->auth->createCustomToken($uid)->toString();
        } catch (\Throwable $e) {
            error_log('[brisko] custom token failed for uid=' . $uid . ': ' . $e->getMessage());
            throw new ApiException('Authentication service is unavailable. Please try again.', 500);
        }
    }

    /**
     * Seeds users/{uid} in RTDB when a database URL is configured. The Flutter
     * app also ensures this record, so a missing database URL is not fatal.
     */
    public function ensureUserRecord(string $uid, string $mobile, bool $isNewUser): void
    {
        if ($this->database === null) {
            return;
        }
        try {
            $ref = $this->database->getReference('users/' . $uid);
            if ($isNewUser || $ref->getSnapshot()->getValue() === null) {
                $now = (int) round(microtime(true) * 1000);
                $ref->update([
                    'phone' => $mobile,
                    'name' => '',
                    'email' => '',
                    'createdAt' => $now,
                    'updatedAt' => $now,
                ]);
            }
        } catch (\Throwable $e) {
            // Non-fatal: the client will create the record after sign-in.
            error_log('[brisko] rtdb seed skipped for uid=' . $uid . ': ' . $e->getMessage());
        }
    }
}
