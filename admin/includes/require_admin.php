<?php

declare(strict_types=1);

require_once __DIR__ . '/bootstrap.php';

if (empty($_SESSION['admin_id'])) {
    brisko_redirect('login.php');
}

$ADMIN = [
    'id' => (string) $_SESSION['admin_id'],
    'username' => (string) ($_SESSION['admin_username'] ?? 'admin'),
    'email' => (string) ($_SESSION['admin_email'] ?? ''),
];
