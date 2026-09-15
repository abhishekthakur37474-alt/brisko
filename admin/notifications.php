<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Notifications';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $title = trim((string) ($_POST['title'] ?? ''));
    $body = trim((string) ($_POST['body'] ?? ''));
    $segment = (string) ($_POST['segment'] ?? 'all');
    try {
        if ($title === '' || $body === '') {
            throw new InvalidArgumentException('Title and message are required.');
        }
        $rtdb = brisko_rtdb();
        $users = brisko_map($rtdb->get('users'));
        $sentInbox = 0;
        $tokens = [];
        foreach ($users as $uid => $user) {
            if (!is_array($user) || !empty($user['isBlocked'])) {
                continue;
            }
            if ($segment === 'with_orders') {
                $orders = $rtdb->get('userOrders/' . $uid);
                if (!is_array($orders) || $orders === []) {
                    continue;
                }
            }
            brisko_notify_user($rtdb, (string) $uid, $title, $body, 'promo');
            $sentInbox++;
            foreach (brisko_user_tokens($user) as $t) {
                $tokens[] = $t;
            }
        }
        $pushed = (new FcmClient(brisko_config()))->sendToTokens($tokens, $title, $body, ['type' => 'promo']);
        brisko_flash('success', 'Sent to ' . $sentInbox . ' inboxes' . ($pushed ? (', ' . $pushed . ' push') : '') . '.');
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('notifications.php');
}

require __DIR__ . '/includes/header.php';
?>
<div class="row">
    <div class="col-lg-6">
        <div class="card p-3">
            <h2 class="h5">Broadcast</h2>
            <p class="text-muted">Writes to each customer inbox and sends FCM when tokens + service account exist.</p>
            <form method="post">
                <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                <div class="mb-3">
                    <label class="form-label" for="title">Title</label>
                    <input class="form-control" id="title" name="title" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="body">Message</label>
                    <textarea class="form-control" id="body" name="body" rows="4" required></textarea>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="segment">Audience</label>
                    <select class="form-select" id="segment" name="segment">
                        <option value="all">All customers</option>
                        <option value="with_orders">Customers with orders</option>
                    </select>
                </div>
                <button class="btn btn-primary" type="submit">Send broadcast</button>
            </form>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
