<?php

declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

if (empty($_SESSION['admin_id'])) {
    // No admin provisioned yet -> first-run registration, otherwise -> login.
    brisko_admin_entry_redirect();
}

$ADMIN = [
    'id' => (string) $_SESSION['admin_id'],
    'username' => (string) ($_SESSION['admin_username'] ?? 'admin'),
    'email' => (string) ($_SESSION['admin_email'] ?? ''),
];
