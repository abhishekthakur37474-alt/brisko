<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';
require_once __DIR__ . '/api/reports.php';

$pageTitle = 'Reports';
$rtdb = brisko_rtdb();
$orders = brisko_map($rtdb->get('orders'));
$products = brisko_map($rtdb->get('products'));
$outlets = brisko_map($rtdb->get('outlets'));
$report = brisko_build_reports($orders, $products);

if (isset($_GET['export']) && $_GET['export'] === 'csv') {
    header('Content-Type: text/csv');
    header('Content-Disposition: attachment; filename="brisko-orders.csv"');
    $out = fopen('php://output', 'w');
    fputcsv($out, ['orderId', 'createdAt', 'status', 'outletId', 'userId', 'finalAmount', 'paymentMethod', 'paymentStatus']);
    foreach ($orders as $id => $o) {
        if (!is_array($o)) {
            continue;
        }
        fputcsv($out, [
            $id,
            brisko_dt($o['createdAt'] ?? 0),
            $o['orderStatus'] ?? '',
            $o['outletId'] ?? '',
            $o['userId'] ?? '',
            $o['finalAmount'] ?? 0,
            $o['paymentMethod'] ?? '',
            $o['paymentStatus'] ?? '',
        ]);
    }
    fclose($out);
    exit;
}

require __DIR__ . '/includes/header.php';
?>
<div class="page-toolbar">
    <p class="text-muted mb-0">Sales pulled from `/orders` in Realtime Database.</p>
    <a class="btn btn-outline-dark" href="reports.php?export=csv">Export CSV</a>
</div>
<div class="row g-3 mb-4">
    <div class="col-6 col-md-4"><div class="stat-card"><div class="label">All-time revenue</div><div class="value"><?= brisko_h(brisko_money($report['revenueAll'])) ?></div></div></div>
    <div class="col-6 col-md-4"><div class="stat-card"><div class="label">Orders</div><div class="value"><?= (int) $report['orderCount'] ?></div></div></div>
    <div class="col-12 col-md-4"><div class="stat-card"><div class="label">Today</div><div class="value"><?= brisko_h(brisko_money($report['revenueToday'])) ?></div></div></div>
</div>
<div class="row g-3">
    <div class="col-lg-6">
        <div class="card p-3">
            <h2 class="h5">Outlet sales</h2>
            <?php foreach ($report['outletSales'] as $oid => $amt): ?>
                <div class="d-flex justify-content-between py-2 border-bottom">
                    <span><?= brisko_h((string) ($outlets[$oid]['name'] ?? $oid)) ?></span>
                    <strong><?= brisko_h(brisko_money($amt)) ?></strong>
                </div>
            <?php endforeach; ?>
            <?php if (empty($report['outletSales'])): ?><p class="empty-note mb-0">No sales.</p><?php endif; ?>
        </div>
    </div>
    <div class="col-lg-6">
        <div class="card p-3">
            <h2 class="h5">Top products</h2>
            <?php foreach ($report['topProducts'] as $row): ?>
                <div class="d-flex justify-content-between py-2 border-bottom">
                    <span><?= brisko_h((string) $row['name']) ?></span>
                    <strong><?= (int) $row['qty'] ?> · <?= brisko_h(brisko_money($row['amount'] ?? 0)) ?></strong>
                </div>
            <?php endforeach; ?>
            <?php if (empty($report['topProducts'])): ?><p class="empty-note mb-0">No sales.</p><?php endif; ?>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
