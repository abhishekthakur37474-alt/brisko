<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/bootstrap.php';

$closed = false;
$error = null;
try {
    $closed = brisko_auth()->hasAny();
} catch (Throwable $e) {
    $error = 'Could not check existing admin accounts.';
}

if ($closed) {
    $message = 'Registration is closed. Contact your existing admin.';
}

if (!$closed && $_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $username = (string) ($_POST['username'] ?? '');
    $email = (string) ($_POST['email'] ?? '');
    $password = (string) ($_POST['password'] ?? '');
    $confirm = (string) ($_POST['confirm'] ?? '');
    if ($password !== $confirm) {
        $error = 'Passwords do not match.';
    } else {
        try {
            brisko_auth()->register($username, $email, $password);
            brisko_flash('success', 'Admin account created. Sign in.');
            brisko_redirect('login.php');
        } catch (Throwable $e) {
            $error = $e->getMessage();
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Register · Brisko Admin</title>
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
        <p class="eyebrow mb-1">First-run setup</p>
        <h1>Create admin</h1>
        <?php if ($closed): ?>
            <div class="alert alert-warning"><?= brisko_h($message) ?></div>
            <a class="btn btn-primary w-100" href="login.php">Go to login</a>
        <?php else: ?>
            <p class="text-muted">This form is available only while no admin exists in RTDB.</p>
            <?php if ($error): ?><div class="alert alert-danger"><?= brisko_h($error) ?></div><?php endif; ?>
            <form method="post">
                <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                <div class="mb-3">
                    <label class="form-label" for="username">Username</label>
                    <input class="form-control" id="username" name="username" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="email">Email</label>
                    <input class="form-control" id="email" name="email" type="email" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="password">Password</label>
                    <input class="form-control" id="password" name="password" type="password" minlength="8" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="confirm">Confirm password</label>
                    <input class="form-control" id="confirm" name="confirm" type="password" minlength="8" required>
                </div>
                <button class="btn btn-primary w-100" type="submit">Create admin</button>
            </form>
        <?php endif; ?>
    </div>
</div>
</body>
</html>
