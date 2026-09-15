<?php
require_once __DIR__.'/helpers/bootstrap.php';
require_once __DIR__.'/services/firebase_service.php';
require_once __DIR__.'/services/cashfree_service.php';
require_once __DIR__.'/services/order_service.php';

$config = brisko_config();
$cashfree = new CashfreeService($config['cashfree']);
$service = new OrderService(firebase_service(), $config['pricing']);

$uid = 'PASTE_REAL_UID_HERE';

$payload = [
    'items' => [
        [
            'productId' => 'PASTE_REAL_PRODUCT_ID_HERE',
            'quantity' => 1,
            'selectedSize' => '',
            'selectedCrust' => '',
            'toppings' => [],
            'addons' => [],
        ],
    ],
    'outletId' => 'PASTE_REAL_OUTLET_ID',
    'orderMode' => 'delivery',
    'receiverName' => 'Test User',
    'receiverPhone' => '9999999999',
    'notes' => '',
    'couponCode' => null,
    'redeemLoyalty' => false,
    'currency' => 'INR',
    'address' => ['line1' => 'Test', 'pincode' => '110001'],
];

try {
    $result = $service->createOnlineOrder($uid, $payload, $cashfree, $config['cashfree']);
    echo "SUCCESS:\n";
    var_dump($result);
} catch (\Throwable $e) {
    echo "FAILED: " . get_class($e) . " -> " . $e->getMessage() . "\n";
}