<?php

declare(strict_types=1);

$current = basename($_SERVER['PHP_SELF'] ?? 'index.php');
$nav = [
    ['href' => 'index.php', 'label' => 'Dashboard', 'icon' => 'bi-speedometer2'],
    ['href' => 'orders.php', 'label' => 'Orders', 'icon' => 'bi-bag-check'],
    ['href' => 'products.php', 'label' => 'Products', 'icon' => 'bi-box-seam'],
    ['href' => 'categories.php', 'label' => 'Categories', 'icon' => 'bi-grid'],
    ['href' => 'outlets.php', 'label' => 'Outlets', 'icon' => 'bi-geo-alt'],
    ['href' => 'coupons.php', 'label' => 'Coupons', 'icon' => 'bi-ticket-perforated'],
    ['href' => 'customers.php', 'label' => 'Customers', 'icon' => 'bi-people'],
    ['href' => 'tickets.php', 'label' => 'Support', 'icon' => 'bi-headset'],
    ['href' => 'notifications.php', 'label' => 'Notifications', 'icon' => 'bi-bell'],
    ['href' => 'loyalty_config.php', 'label' => 'Loyalty', 'icon' => 'bi-star'],
    ['href' => 'reports.php', 'label' => 'Reports', 'icon' => 'bi-graph-up'],
];
?>
<aside class="brisko-sidebar" id="briskoSidebar">
    <div class="brand">
        <span class="logo-mark" aria-hidden="true">B</span>
        <div>
            <strong>Brisko</strong>
            <small>Admin Panel</small>
        </div>
    </div>
    <nav>
        <?php foreach ($nav as $item): ?>
            <a class="<?= $current === $item['href'] ? 'active' : '' ?>" href="<?= brisko_h($item['href']) ?>">
                <i class="bi <?= brisko_h($item['icon']) ?>"></i>
                <span><?= brisko_h($item['label']) ?></span>
            </a>
        <?php endforeach; ?>
    </nav>
</aside>
