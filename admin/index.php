<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';
require_once __DIR__ . '/api/reports.php';

$pageTitle = 'Dashboard';
$rtdb = brisko_rtdb();
$orders = brisko_map($rtdb->get('orders'));
$products = brisko_map($rtdb->get('products'));
$users = brisko_map($rtdb->get('users'));
$tickets = brisko_map($rtdb->get('supportTickets'));
$report = brisko_build_reports($orders, $products);

$recent = $orders;
uasort($recent, static fn ($a, $b) => ((int) ($b['createdAt'] ?? 0)) <=> ((int) ($a['createdAt'] ?? 0)));
$recent = array_slice($recent, 0, 8, true);
$openTickets = 0;
foreach ($tickets as $t) {
    if (is_array($t) && (($t['status'] ?? 'open') === 'open')) {
        $openTickets++;
    }
}

require __DIR__ . '/includes/header.php';
?>
<div class="row g-3 mb-4">
    <div class="col-6 col-xl-3"><div class="stat-card"><div class="label">Orders today</div><div class="value"><?= (int) $report['ordersToday'] ?></div></div></div>
    <div class="col-6 col-xl-3"><div class="stat-card"><div class="label">Revenue today</div><div class="value"><?= brisko_h(brisko_money($report['revenueToday'])) ?></div></div></div>
    <div class="col-6 col-xl-3"><div class="stat-card"><div class="label">Customers</div><div class="value"><?= count($users) ?></div></div></div>
    <div class="col-6 col-xl-3"><div class="stat-card"><div class="label">Open tickets</div><div class="value"><?= $openTickets ?></div></div></div>
</div>
<div class="row g-3">
    <div class="col-lg-8">
        <div class="table-card">
            <div class="p-3 d-flex justify-content-between align-items-center">
                <h2 class="h5 mb-0">Latest orders</h2>
                <a href="orders.php">View all</a>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead><tr><th>Order</th><th>Status</th><th>Amount</th><th>When</th></tr></thead>
                    <tbody>
                    <?php if ($recent === []): ?>
                        <tr><td colspan="4" class="empty-note">No orders yet.</td></tr>
                    <?php else: foreach ($recent as $id => $o): $st = (string) ($o['orderStatus'] ?? 'placed'); ?>
                        <tr>
                            <td><a href="orders.php?id=<?= brisko_h((string) $id) ?>"><?= brisko_h((string) $id) ?></a></td>
                            <td><span class="badge-status st-<?= brisko_h($st) ?>"><?= brisko_h(brisko_status_label($st)) ?></span></td>
                            <td><?= brisko_h(brisko_money($o['finalAmount'] ?? 0)) ?></td>
                            <td><?= brisko_h(brisko_dt($o['createdAt'] ?? 0)) ?></td>
                        </tr>
                    <?php endforeach; endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="col-lg-4">
        <div class="card p-3 mb-3">
            <h2 class="h5">Top products</h2>
            <?php if (empty($report['topProducts'])): ?>
                <p class="empty-note mb-0">No sales yet.</p>
            <?php else: foreach ($report['topProducts'] as $row): ?>
                <div class="d-flex justify-content-between py-2 border-bottom">
                    <span><?= brisko_h((string) $row['name']) ?></span>
                    <strong><?= (int) $row['qty'] ?></strong>
                </div>
            <?php endforeach; endif; ?>
        </div>
        <div class="card p-3">
            <h2 class="h5">Status mix</h2>
            <?php foreach (($report['statusCounts'] ?: ['placed' => 0]) as $k => $v): ?>
                <div class="d-flex justify-content-between py-1"><span><?= brisko_h(brisko_status_label((string) $k)) ?></span><strong><?= (int) $v ?></strong></div>
            <?php endforeach; ?>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
