<?php

declare(strict_types=1);

class AdminAuth
{
    private RtdbClient $rtdb;

    public function __construct(RtdbClient $rtdb)
    {
        $this->rtdb = $rtdb;
    }

    public function all(): array
    {
        $node = $this->rtdb->get('adminAuth');
        if (!is_array($node) || $node === []) {
            return [];
        }
        $out = [];
        foreach ($node as $id => $row) {
            if (is_array($row)) {
                $out[(string) $id] = $row;
            }
        }
        return $out;
    }

    public function hasAny(): bool
    {
        return $this->all() !== [];
    }

    public function findByUsername(string $username): ?array
    {
        $username = mb_strtolower(trim($username));
        foreach ($this->all() as $id => $row) {
            $u = mb_strtolower(trim((string) ($row['username'] ?? '')));
            if ($u === $username) {
                $row['_id'] = $id;
                return $row;
            }
        }
        return null;
    }

    public function findByUsernameAndEmail(string $username, string $email): ?array
    {
        $username = mb_strtolower(trim($username));
        $email = mb_strtolower(trim($email));
        foreach ($this->all() as $id => $row) {
            $u = mb_strtolower(trim((string) ($row['username'] ?? '')));
            $e = mb_strtolower(trim((string) ($row['email'] ?? '')));
            if ($u === $username && $e === $email) {
                $row['_id'] = $id;
                return $row;
            }
        }
        return null;
    }

    public function register(string $username, string $email, string $password): array
    {
        if ($this->hasAny()) {
            throw new RuntimeException('Registration is closed.');
        }
        $username = trim($username);
        $email = trim($email);
        if ($username === '' || !preg_match('/^[A-Za-z0-9._-]{3,32}$/', $username)) {
            throw new InvalidArgumentException('Username must be 3-32 letters, numbers, dot, dash or underscore.');
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Enter a valid email address.');
        }
        if (strlen($password) < 8) {
            throw new InvalidArgumentException('Password must be at least 8 characters.');
        }
        $now = (int) round(microtime(true) * 1000);
        $record = [
            'username' => $username,
            'email' => $email,
            'passwordHash' => password_hash($password, PASSWORD_BCRYPT),
            'role' => 'super_admin',
            'createdAt' => $now,
            'updatedAt' => $now,
        ];
        $res = $this->rtdb->post('adminAuth', $record);
        $id = is_array($res) ? (string) ($res['name'] ?? '') : '';
        if ($id === '') {
            $id = 'admin_' . $now;
            $this->rtdb->put('adminAuth/' . $id, $record);
        }
        $record['_id'] = $id;
        return $record;
    }

    public function verify(string $username, string $password): ?array
    {
        $row = $this->findByUsername($username);
        if ($row === null) {
            return null;
        }
        $hash = (string) ($row['passwordHash'] ?? '');
        if ($hash === '' || !password_verify($password, $hash)) {
            return null;
        }
        return $row;
    }

    public function updateCredentials(string $adminId, array $fields): void
    {
        $patch = ['updatedAt' => (int) round(microtime(true) * 1000)];
        if (isset($fields['username'])) {
            $username = trim((string) $fields['username']);
            if ($username === '' || !preg_match('/^[A-Za-z0-9._-]{3,32}$/', $username)) {
                throw new InvalidArgumentException('Username must be 3-32 letters, numbers, dot, dash or underscore.');
            }
            $existing = $this->findByUsername($username);
            if ($existing && ($existing['_id'] ?? '') !== $adminId) {
                throw new InvalidArgumentException('That username is already in use.');
            }
            $patch['username'] = $username;
        }
        if (isset($fields['email'])) {
            $email = trim((string) $fields['email']);
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                throw new InvalidArgumentException('Enter a valid email address.');
            }
            $patch['email'] = $email;
        }
        if (isset($fields['password']) && $fields['password'] !== '') {
            $password = (string) $fields['password'];
            if (strlen($password) < 8) {
                throw new InvalidArgumentException('Password must be at least 8 characters.');
            }
            $patch['passwordHash'] = password_hash($password, PASSWORD_BCRYPT);
        }
        $this->rtdb->patch('adminAuth/' . $adminId, $patch);
    }
}
