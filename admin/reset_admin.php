<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/bootstrap.php';

// Nothing to reset yet: send the visitor to first-run setup.
if (!brisko_has_admin()) {
    brisko_redirect('register.php');
}

$config = brisko_config();
$expectedProjectId = brisko_project_id();
$expectedDbUrl = brisko_normalize_rtdb_url((string) ($config['rtdb_base_url'] ?? ''));

$error = null;
$ipKey = 'resetadmin_' . preg_replace('/[^0-9a-fA-F.:]/', '_', (string) ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
$locked = brisko_is_locked($ipKey);

if (!$locked && $_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $projectId = trim((string) ($_POST['project_id'] ?? ''));
    $dbUrl = brisko_normalize_rtdb_url((string) ($_POST['database_url'] ?? ''));
    $confirm = strtoupper(trim((string) ($_POST['confirm'] ?? '')));
    $projectOk = $expectedProjectId !== '' && hash_equals(strtolower($expectedProjectId), strtolower($projectId));
    $dbOk = $expectedDbUrl !== '' && hash_equals($expectedDbUrl, $dbUrl);
    if (!$projectOk || !$dbOk) {
        brisko_fail_attempt($ipKey);
        $error = 'Project ID or Database URL does not match this panel.';
    } elseif ($confirm !== 'RESET') {
        $error = 'Type RESET to confirm.';
    } else {
        try {
            $removed = brisko_auth()->deleteAll();
            brisko_clear_attempts($ipKey);
            unset(
                $_SESSION['admin_id'],
                $_SESSION['admin_username'],
                $_SESSION['admin_email'],
                $_SESSION['reset_admin_id']
            );
            session_regenerate_id(true);
            brisko_flash('success', 'Admin account removed. Create a new admin to continue.');
            brisko_redirect('register.php');
        } catch (Throwable $e) {
            $error = 'Could not reset the admin account. Check the service account / RTDB access.';
        }
    }
}

// A failed attempt above may have just locked this IP.
$locked = brisko_is_locked($ipKey);
if ($locked) {
    $error = 'Too many attempts. Try again later.';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reset admin · Brisko Admin</title>
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
        <p class="eyebrow mb-1">Danger zone</p>
        <h1>Reset admin</h1>
        <p class="text-muted">
            This removes every admin account and reopens first-run registration.
            Confirm the Firebase details below to continue.
        </p>
        <?php if ($error): ?>
            <div class="alert alert-danger"><?= brisko_h($error) ?></div>
        <?php endif; ?>
        <?php if ($locked): ?>
            <div class="alert alert-warning mb-0">Too many attempts. Try again later.</div>
        <?php else: ?>
            <div class="alert alert-danger">
                This cannot be undone. All admin logins will stop working immediately.
            </div>
            <form method="post" novalidate>
                <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                <div class="mb-3">
                    <label class="form-label" for="project_id">Firebase project ID</label>
                    <input class="form-control" id="project_id" name="project_id" required autocomplete="off" placeholder="your-project-id">
                </div>
                <div class="mb-3">
                    <label class="form-label" for="database_url">Database URL</label>
                    <input class="form-control" id="database_url" name="database_url" required autocomplete="off" placeholder="https://your-project-default-rtdb.firebaseio.com">
                </div>
                <div class="mb-3">
                    <label class="form-label" for="confirm">Type <strong>RESET</strong> to confirm</label>
                    <input class="form-control" id="confirm" name="confirm" required autocomplete="off" placeholder="RESET">
                </div>
                <button class="btn btn-danger w-100" type="submit">Remove admin &amp; start over</button>
            </form>
            <p class="text-center mt-3 mb-0"><a href="login.php">Back to login</a></p>
        <?php endif; ?>
    </div>
</div>
</body>
</html>
