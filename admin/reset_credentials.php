<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/bootstrap.php';

$step = 'identify';
$error = null;
$admin = null;

$ipKey = 'reset_' . preg_replace('/[^0-9a-fA-F.:]/', '_', (string) ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));

if (brisko_is_locked($ipKey)) {
    $error = 'Too many attempts. Try again later.';
    $step = 'locked';
}

if ($step !== 'locked' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $action = (string) ($_POST['action'] ?? 'identify');
    if ($action === 'identify') {
        $username = (string) ($_POST['username'] ?? '');
        $email = (string) ($_POST['email'] ?? '');
        try {
            $found = brisko_auth()->findByUsernameAndEmail($username, $email);
            if ($found) {
                $_SESSION['reset_admin_id'] = $found['_id'];
                $step = 'update';
                $admin = $found;
            } else {
                brisko_fail_attempt($ipKey);
                $error = 'Username and email do not match.';
            }
        } catch (Throwable $e) {
            $error = 'Could not verify credentials.';
        }
    } elseif ($action === 'update') {
        $adminId = (string) ($_SESSION['reset_admin_id'] ?? '');
        if ($adminId === '') {
            $error = 'Start again from username and email.';
        } else {
            $password = (string) ($_POST['password'] ?? '');
            $confirm = (string) ($_POST['confirm'] ?? '');
            if ($password !== '' && $password !== $confirm) {
                $error = 'Passwords do not match.';
                $step = 'update';
            } else {
                try {
                    $fields = [
                        'username' => (string) ($_POST['username'] ?? ''),
                        'email' => (string) ($_POST['email'] ?? ''),
                    ];
                    if ($password !== '') {
                        $fields['password'] = $password;
                    }
                    brisko_auth()->updateCredentials($adminId, $fields);
                    unset($_SESSION['reset_admin_id'], $_SESSION['admin_id'], $_SESSION['admin_username'], $_SESSION['admin_email']);
                    brisko_flash('success', 'Credentials updated. Sign in with the new details.');
                    brisko_redirect('login.php');
                } catch (Throwable $e) {
                    $error = $e->getMessage();
                    $step = 'update';
                }
            }
        }
    }
} elseif (!empty($_SESSION['reset_admin_id']) && $step !== 'locked') {
    $step = 'update';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reset · Brisko Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Poppins:wght@700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="assets/css/admin.css" rel="stylesheet">
</head>
<body>
<div class="auth-wrap">
    <div class="auth-card">
        <div class="auth-mark mb-3">B</div>
        <h1>Reset credentials</h1>
        <p class="text-muted">Direct URL only. Verify existing username and email first.</p>
        <?php if ($error): ?><div class="alert alert-danger"><?= brisko_h($error) ?></div><?php endif; ?>
        <?php if ($step === 'identify' || $step === 'locked'): ?>
            <form method="post">
                <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                <input type="hidden" name="action" value="identify">
                <div class="mb-3">
                    <label class="form-label" for="username">Existing username</label>
                    <input class="form-control" id="username" name="username" required <?= $step === 'locked' ? 'disabled' : '' ?>>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="email">Existing email</label>
                    <input class="form-control" id="email" name="email" type="email" required <?= $step === 'locked' ? 'disabled' : '' ?>>
                </div>
                <button class="btn btn-primary w-100" type="submit" <?= $step === 'locked' ? 'disabled' : '' ?>>Continue</button>
            </form>
        <?php else: ?>
            <form method="post">
                <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                <input type="hidden" name="action" value="update">
                <div class="mb-3">
                    <label class="form-label" for="username">New username</label>
                    <input class="form-control" id="username" name="username" value="<?= brisko_h((string) ($admin['username'] ?? '')) ?>" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="email">New email</label>
                    <input class="form-control" id="email" name="email" type="email" value="<?= brisko_h((string) ($admin['email'] ?? '')) ?>" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="password">New password</label>
                    <input class="form-control" id="password" name="password" type="password" minlength="8">
                </div>
                <div class="mb-3">
                    <label class="form-label" for="confirm">Confirm password</label>
                    <input class="form-control" id="confirm" name="confirm" type="password" minlength="8">
                </div>
                <button class="btn btn-primary w-100" type="submit">Save credentials</button>
            </form>
        <?php endif; ?>
    </div>
</div>
</body>
</html>
