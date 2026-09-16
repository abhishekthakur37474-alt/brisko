<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/bootstrap.php';

if (!empty($_SESSION['admin_id'])) {
    brisko_redirect('index.php');
}

// No admin account exists yet: send the visitor to first-run setup instead.
if (!brisko_has_admin()) {
    brisko_redirect('register.php');
}

$error = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $username = trim((string) ($_POST['username'] ?? ''));
    $password = (string) ($_POST['password'] ?? '');
    $ipKey = 'ip_' . preg_replace('/[^0-9a-fA-F.:]/', '_', (string) ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
    $userKey = 'user_' . strtolower($username);
    if (brisko_is_locked($ipKey) || brisko_is_locked($userKey)) {
        $error = 'Too many attempts. Try again later.';
    } else {
        try {
            $admin = brisko_auth()->verify($username, $password);
            if ($admin) {
                session_regenerate_id(true);
                $_SESSION['admin_id'] = (string) $admin['_id'];
                $_SESSION['admin_username'] = (string) $admin['username'];
                $_SESSION['admin_email'] = (string) ($admin['email'] ?? '');
                brisko_clear_attempts($ipKey);
                brisko_clear_attempts($userKey);
                brisko_redirect('index.php');
            }
            brisko_fail_attempt($ipKey);
            brisko_fail_attempt($userKey);
            $error = 'Invalid username or password';
        } catch (Throwable $e) {
            $error = 'Could not reach Firebase. Check service account / RTDB access.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login · Brisko Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Poppins:wght@700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="assets/css/admin.css" rel="stylesheet">
</head>
<body>
<div class="auth-wrap">
    <div class="auth-card">
        <div class="auth-mark mb-3">B</div>
        <p class="eyebrow mb-1">Brisko Pizza</p>
        <h1>Admin login</h1>
        <p class="text-muted">Username and password. Separate from customer Google sign-in.</p>
        <?php if ($error): ?>
            <div class="alert alert-danger"><?= brisko_h($error) ?></div>
        <?php endif; ?>
        <form method="post" novalidate>
            <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
            <div class="mb-3">
                <label class="form-label" for="username">Username</label>
                <input class="form-control" id="username" name="username" required autocomplete="username">
            </div>
            <div class="mb-3">
                <label class="form-label" for="password">Password</label>
                <input class="form-control" id="password" name="password" type="password" required autocomplete="current-password">
            </div>
            <button class="btn btn-primary w-100" type="submit">Sign in</button>
        </form>
    </div>
</div>
</body>
</html>
