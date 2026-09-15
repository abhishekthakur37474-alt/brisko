<?php

declare(strict_types=1);

require_once __DIR__ . '/auth_middleware.php';

function brisko_build_reports(array $orders, array $products): array
{
    $todayStart = (int) (strtotime('today') * 1000);
    $todayOrders = 0;
    $todayRevenue = 0.0;
    $revenue = 0.0;
    $statusCounts = [];
    $productSales = [];
    $outletSales = [];
    foreach ($orders as $id => $order) {
        if (!is_array($order)) {
            continue;
        }
        $status = (string) ($order['orderStatus'] ?? 'placed');
        $statusCounts[$status] = ($statusCounts[$status] ?? 0) + 1;
        $amount = (float) ($order['finalAmount'] ?? 0);
        if ($status !== 'cancelled') {
            $revenue += $amount;
            $created = (int) ($order['createdAt'] ?? 0);
            if ($created >= $todayStart) {
                $todayOrders++;
                $todayRevenue += $amount;
            }
            $outlet = (string) ($order['outletId'] ?? 'unknown');
            $outletSales[$outlet] = ($outletSales[$outlet] ?? 0) + $amount;
            $items = $order['items'] ?? [];
            if (is_array($items)) {
                foreach ($items as $item) {
                    if (!is_array($item)) {
                        continue;
                    }
                    $pid = (string) ($item['productId'] ?? $item['name'] ?? 'item');
                    $productSales[$pid]['name'] = (string) ($item['name'] ?? $pid);
                    $productSales[$pid]['qty'] = ($productSales[$pid]['qty'] ?? 0) + (int) ($item['quantity'] ?? 1);
                    $productSales[$pid]['amount'] = ($productSales[$pid]['amount'] ?? 0) + (float) ($item['totalPrice'] ?? 0);
                }
            }
        }
    }
    uasort($productSales, static fn ($a, $b) => ($b['qty'] ?? 0) <=> ($a['qty'] ?? 0));
    return [
        'ordersToday' => $todayOrders,
        'revenueToday' => $todayRevenue,
        'revenueAll' => $revenue,
        'orderCount' => count($orders),
        'statusCounts' => $statusCounts,
        'topProducts' => array_slice($productSales, 0, 8, true),
        'outletSales' => $outletSales,
        'productCount' => count($products),
    ];
}

if (basename((string) ($_SERVER['SCRIPT_FILENAME'] ?? '')) === 'reports.php' && isset($_GET['format']) && $_GET['format'] === 'json') {
    header('Content-Type: application/json');
    $rtdb = brisko_rtdb();
    echo json_encode(brisko_build_reports(brisko_map($rtdb->get('orders')), brisko_map($rtdb->get('products'))));
}
