<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Support tickets';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $id = (string) ($_POST['id'] ?? '');
    $status = (string) ($_POST['status'] ?? 'open');
    if ($id !== '' && in_array($status, ['open', 'closed'], true)) {
        $rtdb->patch('supportTickets/' . $id, ['status' => $status, 'updatedAt' => brisko_now_ms()]);
        brisko_flash('success', 'Ticket updated.');
    }
    brisko_redirect('tickets.php');
}

$tickets = brisko_map($rtdb->get('supportTickets'));
$users = brisko_map($rtdb->get('users'));
uasort($tickets, static fn ($a, $b) => ((int) ($b['createdAt'] ?? 0)) <=> ((int) ($a['createdAt'] ?? 0)));

require __DIR__ . '/includes/header.php';
?>
<div class="table-card">
    <div class="table-responsive">
    <table class="table">
        <thead><tr><th>When</th><th>Customer</th><th>Type</th><th>Message</th><th>Status</th><th></th></tr></thead>
        <tbody>
        <?php if ($tickets === []): ?>
            <tr><td colspan="6" class="empty-note">No tickets.</td></tr>
        <?php else: foreach ($tickets as $id => $t):
            $uid = (string) ($t['userId'] ?? '');
            $name = $users[$uid]['name'] ?? $uid;
            $st = (string) ($t['status'] ?? 'open');
            ?>
            <tr>
                <td><?= brisko_h(brisko_dt($t['createdAt'] ?? 0)) ?></td>
                <td><?= brisko_h((string) $name) ?></td>
                <td><?= brisko_h((string) ($t['type'] ?? '')) ?></td>
                <td><?= brisko_h((string) ($t['message'] ?? '')) ?></td>
                <td><span class="badge-status <?= $st === 'open' ? 'st-preparing' : 'st-delivered' ?>"><?= brisko_h($st) ?></span></td>
                <td>
                    <form method="post">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="id" value="<?= brisko_h((string) $id) ?>">
                        <input type="hidden" name="status" value="<?= $st === 'open' ? 'closed' : 'open' ?>">
                        <button class="btn btn-sm btn-outline-dark" type="submit"><?= $st === 'open' ? 'Close' : 'Reopen' ?></button>
                    </form>
                </td>
            </tr>
        <?php endforeach; endif; ?>
        </tbody>
    </table>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
