<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Customers';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $uid = (string) ($_POST['uid'] ?? '');
    $action = (string) ($_POST['action'] ?? '');
    try {
        if ($uid === '') {
            throw new InvalidArgumentException('Customer id required.');
        }
        if ($action === 'block') {
            $rtdb->patch('users/' . $uid, ['isBlocked' => true]);
            brisko_flash('success', 'Customer blocked.');
        } elseif ($action === 'unblock') {
            $rtdb->patch('users/' . $uid, ['isBlocked' => false]);
            brisko_flash('success', 'Customer unblocked.');
        } elseif ($action === 'role') {
            $role = (string) ($_POST['role'] ?? 'customer');
            if (!in_array($role, ['customer', 'admin', 'outlet_manager'], true)) {
                $role = 'customer';
            }
            $rtdb->patch('users/' . $uid, ['role' => $role]);
            brisko_flash('success', 'Role updated.');
        }
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('customers.php');
}

$users = brisko_map($rtdb->get('users'));
uasort($users, static fn ($a, $b) => ((int) ($b['createdAt'] ?? 0)) <=> ((int) ($a['createdAt'] ?? 0)));
$q = mb_strtolower(trim((string) ($_GET['q'] ?? '')));
if ($q !== '') {
    $users = array_filter($users, static function ($u) use ($q) {
        if (!is_array($u)) {
            return false;
        }
        $hay = mb_strtolower(($u['name'] ?? '') . ' ' . ($u['email'] ?? '') . ' ' . ($u['phone'] ?? ''));
        return str_contains($hay, $q);
    });
}

require __DIR__ . '/includes/header.php';
?>
<form class="mb-3" method="get">
    <div class="input-group search-bar">
        <input class="form-control" name="q" value="<?= brisko_h($q) ?>" placeholder="Search name, email, phone">
        <button class="btn btn-dark" type="submit">Search</button>
    </div>
</form>
<div class="table-card">
    <div class="table-responsive">
    <table class="table">
        <thead><tr><th>Customer</th><th>Contact</th><th>Points</th><th>Role</th><th></th></tr></thead>
        <tbody>
        <?php foreach ($users as $uid => $u): ?>
            <tr>
                <td>
                    <strong><?= brisko_h((string) ($u['name'] ?? 'Guest')) ?></strong>
                    <div class="small text-muted"><?= brisko_h((string) $uid) ?></div>
                    <?php if (!empty($u['isBlocked'])): ?><span class="badge-status st-cancelled">Blocked</span><?php endif; ?>
                </td>
                <td><?= brisko_h((string) ($u['email'] ?? '')) ?><br><?= brisko_h((string) ($u['phone'] ?? '')) ?></td>
                <td><?= (int) ($u['loyaltyPoints'] ?? 0) ?></td>
                <td>
                    <form method="post" class="d-flex gap-2">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="role">
                        <input type="hidden" name="uid" value="<?= brisko_h((string) $uid) ?>">
                        <select class="form-select form-select-sm" name="role">
                            <?php foreach (['customer', 'outlet_manager', 'admin'] as $role): ?>
                                <option value="<?= $role ?>" <?= (($u['role'] ?? 'customer') === $role) ? 'selected' : '' ?>><?= $role ?></option>
                            <?php endforeach; ?>
                        </select>
                        <button class="btn btn-sm btn-outline-dark" type="submit">Save</button>
                    </form>
                </td>
                <td class="text-end">
                    <form method="post">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="uid" value="<?= brisko_h((string) $uid) ?>">
                        <?php if (!empty($u['isBlocked'])): ?>
                            <input type="hidden" name="action" value="unblock">
                            <button class="btn btn-sm btn-outline-dark" type="submit">Unblock</button>
                        <?php else: ?>
                            <input type="hidden" name="action" value="block">
                            <button class="btn btn-sm btn-outline-danger" type="submit">Block</button>
                        <?php endif; ?>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
