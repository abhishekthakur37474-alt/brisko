<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Orders';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $action = (string) ($_POST['action'] ?? '');
    $orderId = trim((string) ($_POST['orderId'] ?? ''));
    try {
        if ($orderId === '') {
            throw new InvalidArgumentException('Order id required.');
        }
        if ($action === 'status') {
            brisko_update_order_status($rtdb, $orderId, (string) ($_POST['status'] ?? ''));
            brisko_flash('success', 'Order status updated.');
        } elseif ($action === 'upi_verify') {
            brisko_review_upi_payment($rtdb, $orderId, true, (string) ($_POST['note'] ?? ''));
            brisko_flash('success', 'UPI payment marked as received.');
        } elseif ($action === 'upi_reject') {
            brisko_review_upi_payment($rtdb, $orderId, false, (string) ($_POST['note'] ?? ''));
            brisko_flash('success', 'UPI payment marked as not received.');
        } elseif ($action === 'upi_refund') {
            brisko_refund_upi_payment($rtdb, $orderId, (string) ($_POST['refundRef'] ?? ''));
            brisko_flash('success', 'UPI order marked as refunded.');
        } elseif ($action === 'invoice') {
            $order = $rtdb->get('orders/' . $orderId);
            if (!is_array($order)) {
                throw new RuntimeException('Order not found.');
            }
            $dir = (string) (brisko_config()['invoice_dir'] ?? __DIR__ . '/invoices');
            PdfInvoice::writeHtml($dir, $orderId, $order);
            $url = brisko_invoice_url($orderId);
            $rtdb->patch('orders/' . $orderId, ['invoiceUrl' => $url]);
            brisko_flash('success', 'Invoice generated.');
        }
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    $back = ['id' => $orderId];
    $stKeep = trim((string) ($_POST['filter_status'] ?? ''));
    $outKeep = trim((string) ($_POST['filter_outlet'] ?? ''));
    $qKeep = trim((string) ($_POST['filter_q'] ?? ''));
    $typeKeep = brisko_order_type_key((string) ($_POST['filter_type'] ?? ''));
    if ($stKeep !== '') {
        $back['status'] = $stKeep;
    }
    if ($outKeep !== '') {
        $back['outlet'] = $outKeep;
    }
    if ($qKeep !== '') {
        $back['q'] = $qKeep;
    }
    if (trim((string) ($_POST['filter_type'] ?? '')) !== '') {
        $back['type'] = $typeKeep;
    }
    brisko_redirect('orders.php?' . http_build_query(array_filter($back)));
}

$orders = brisko_map($rtdb->get('orders'));
$users = brisko_map($rtdb->get('users'));
$outlets = brisko_map($rtdb->get('outlets'));
uasort($orders, static fn ($a, $b) => ((int) ($b['createdAt'] ?? 0)) <=> ((int) ($a['createdAt'] ?? 0)));

$filter = (string) ($_GET['status'] ?? '');
$outletFilter = (string) ($_GET['outlet'] ?? '');
$typeFilter = brisko_order_type_key((string) ($_GET['type'] ?? ''));
$searchQuery = trim((string) ($_GET['q'] ?? ''));
if ($filter !== '') {
    $orders = array_filter($orders, static fn ($o) => is_array($o) && ($o['orderStatus'] ?? '') === $filter);
}
if ($outletFilter !== '') {
    $orders = array_filter($orders, static fn ($o) => is_array($o) && ($o['outletId'] ?? '') === $outletFilter);
}
if (trim((string) ($_GET['type'] ?? '')) !== '') {
    $orders = array_filter($orders, static fn ($o) => is_array($o) && brisko_order_type_key((string) ($o['orderType'] ?? '')) === $typeFilter);
}
if ($searchQuery !== '') {
    $needle = mb_strtolower($searchQuery);
    $orders = array_filter($orders, static function ($o, $oid) use ($needle) {
        if (!is_array($o)) {
            return false;
        }
        return str_contains(mb_strtolower((string) $oid), $needle);
    }, ARRAY_FILTER_USE_BOTH);
}

$detailId = (string) ($_GET['id'] ?? '');
$detail = $detailId !== '' && isset($orders[$detailId]) ? $orders[$detailId] : ($detailId !== '' ? $rtdb->get('orders/' . $detailId) : null);
$queryKeep = [];
if ($filter !== '') {
    $queryKeep['status'] = $filter;
}
if ($outletFilter !== '') {
    $queryKeep['outlet'] = $outletFilter;
}
if ($searchQuery !== '') {
    $queryKeep['q'] = $searchQuery;
}
if (trim((string) ($_GET['type'] ?? '')) !== '') {
    $queryKeep['type'] = $typeFilter;
}

if (!function_exists('array_is_list')) {
    function array_is_list(array $arr): bool
    {
        $i = 0;
        foreach ($arr as $k => $v) {
            if ($k !== $i++) {
                return false;
            }
        }
        return true;
    }
}
if (!function_exists('str_contains')) {
    function str_contains(string $haystack, string $needle): bool
    {
        return $needle === '' || strpos($haystack, $needle) !== false;
    }
}

function brisko_order_items(array $order): array
{
    $items = $order['items'] ?? [];
    if (!is_array($items) || $items === []) {
        return [];
    }
    if (!array_is_list($items)) {
        ksort($items);
        $items = array_values($items);
    }
    return array_values(array_filter($items, static fn ($row) => is_array($row)));
}

function brisko_map_names($node): string
{
    if (!is_array($node) || $node === []) {
        return '';
    }
    $out = [];
    foreach ($node as $key => $val) {
        if (is_array($val)) {
            $out[] = (string) ($val['name'] ?? $key);
            continue;
        }
        if (is_numeric($val) && is_string($key)) {
            $label = brisko_pretty_option($key);
            $out[] = ((float) $val) > 0 ? ($label . ' (+' . brisko_money($val) . ')') : $label;
            continue;
        }
        $label = is_string($key) && !is_numeric($key) ? $key : (string) $val;
        $out[] = brisko_pretty_option($label);
    }
    return implode(', ', $out);
}

function brisko_pretty_option(string $value): string
{
    $value = trim($value);
    if ($value === '') {
        return '';
    }
    return ucwords(str_replace('_', ' ', $value));
}

require __DIR__ . '/includes/header.php';
?>
<form class="row g-2 mb-3" method="get">
    <div class="col-12 col-sm-6 col-lg-3">
        <select class="form-select" name="status" onchange="this.form.submit()">
            <option value="">All statuses</option>
            <?php foreach (['placed','confirmed','preparing','ready','out_for_delivery','delivered','cancelled'] as $st): ?>
                <option value="<?= $st ?>" <?= $filter === $st ? 'selected' : '' ?>><?= brisko_h(brisko_status_label($st)) ?></option>
            <?php endforeach; ?>
        </select>
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
        <select class="form-select" name="outlet" onchange="this.form.submit()">
            <option value="">All outlets</option>
            <?php foreach ($outlets as $oid => $o): ?>
                <option value="<?= brisko_h((string) $oid) ?>" <?= $outletFilter === $oid ? 'selected' : '' ?>><?= brisko_h((string) ($o['name'] ?? $oid)) ?></option>
            <?php endforeach; ?>
        </select>
    </div>
    <div class="col-12 col-sm-6 col-lg-3">
        <div class="input-group">
            <span class="input-group-text bg-white"><i class="bi bi-search"></i></span>
            <input type="text" class="form-control" name="q" value="<?= brisko_h($searchQuery) ?>" placeholder="Order number" autocomplete="off">
        </div>
    </div>
    <div class="col-12 col-sm-6 col-lg-2 d-grid">
        <button class="btn btn-dark" type="submit">Search</button>
    </div>
</form>
<div class="row g-3">
    <div class="col-12">
        <div class="table-card">
            <div class="table-responsive">
                <table class="table">
                <thead><tr><th>Order</th><th>Customer</th><th>Items</th><th>Status</th><th>Amount</th><th></th></tr></thead>
                <tbody>
                <?php if ($orders === []): ?>
                    <tr><td colspan="6" class="empty-note">No orders.</td></tr>
                <?php else: foreach ($orders as $id => $o):
                    if (!is_array($o)) {
                        continue;
                    }
                    $st = (string) ($o['orderStatus'] ?? 'placed');
                    $uid = (string) ($o['userId'] ?? '');
                    $uname = is_array($users[$uid] ?? null) ? ($users[$uid]['name'] ?? $uid) : $uid;
                    $rowItems = brisko_order_items($o);
                    $itemNames = [];
                    $itemQty = 0;
                    foreach ($rowItems as $rowItem) {
                        $qty = (int) ($rowItem['quantity'] ?? 1);
                        $itemQty += $qty;
                        $itemNames[] = (string) ($rowItem['name'] ?? 'Item') . ' x' . $qty;
                    }
                    $viewQuery = http_build_query($queryKeep + ['id' => (string) $id]);
                    ?>
                    <tr class="<?= $detailId === (string) $id ? 'order-row-active' : '' ?>">
                        <td>
                            <a href="orders.php?<?= brisko_h($viewQuery) ?>"><?= brisko_h((string) $id) ?></a>
                            <div class="small text-muted"><?= brisko_h(brisko_dt($o['createdAt'] ?? 0)) ?></div>
                        </td>
                        <td><?= brisko_h((string) $uname) ?></td>
                        <td>
                            <div><?= $itemQty ?> item<?= $itemQty === 1 ? '' : 's' ?></div>
                            <div class="small text-muted"><?= brisko_h($itemNames === [] ? 'No items' : implode(', ', array_slice($itemNames, 0, 2))) ?><?= count($itemNames) > 2 ? '…' : '' ?></div>
                        </td>
                        <td><span class="badge-status st-<?= brisko_h($st) ?>"><?= brisko_h(brisko_status_label($st)) ?></span></td>
                        <td><?= brisko_h(brisko_money($o['finalAmount'] ?? 0)) ?></td>
                        <td class="text-end action-cell">
                            <a class="btn btn-icon btn-outline-dark" title="View" href="orders.php?<?= brisko_h($viewQuery) ?>"><i class="bi bi-eye"></i></a>
                            <?php $next = brisko_next_status($st); if ($next): ?>
                                <form method="post" class="d-inline">
                                    <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                                    <input type="hidden" name="action" value="status">
                                    <input type="hidden" name="orderId" value="<?= brisko_h((string) $id) ?>">
                                    <input type="hidden" name="status" value="<?= brisko_h($next) ?>">
                                    <?php if ($filter !== ''): ?><input type="hidden" name="filter_status" value="<?= brisko_h($filter) ?>"><?php endif; ?>
                                    <?php if ($outletFilter !== ''): ?><input type="hidden" name="filter_outlet" value="<?= brisko_h($outletFilter) ?>"><?php endif; ?>
                                    <?php if ($searchQuery !== ''): ?><input type="hidden" name="filter_q" value="<?= brisko_h($searchQuery) ?>"><?php endif; ?>
                                    <button class="btn btn-icon btn-primary" type="submit" title="Mark <?= brisko_h(brisko_status_label($next)) ?>"><i class="bi bi-check2"></i></button>
                                </form>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; endif; ?>
                </tbody>
            </table>
            </div>
        </div>
    </div>
</div>
<?php if (is_array($detail)):
        $st = (string) ($detail['orderStatus'] ?? 'placed');
        $items = brisko_order_items($detail);
        $addr = is_array($detail['addressSnapshot'] ?? null) ? $detail['addressSnapshot'] : [];
        $closeQuery = http_build_query($queryKeep);
        $uid = (string) ($detail['userId'] ?? '');
        $customer = is_array($users[$uid] ?? null) ? $users[$uid] : [];
        $outletName = (string) ($outlets[$detail['outletId'] ?? '']['name'] ?? ($detail['outletId'] ?? '-'));
        $outletMapUrl = trim((string) ($outlets[$detail['outletId'] ?? '']['googleMapsUrl'] ?? ''));
        $orderType = brisko_order_type_label((string) ($detail['orderType'] ?? ''));
        $receiverName = trim((string) ($detail['receiverName'] ?? ''));
        $receiverPhone = trim((string) ($addr['receiverPhone'] ?? ''));
        $payMethod = (string) ($detail['paymentMethod'] ?? $detail['payment']['method'] ?? 'cod');
        $payStatus = (string) ($detail['paymentStatus'] ?? $detail['payment']['status'] ?? '');
        // COD is collected on delivery; older delivered orders may still store
        // "pending" so surface the correct status without a data migration.
        if ($st === 'delivered' && strtolower($payMethod) === 'cod' && $payStatus !== 'paid') {
            $payStatus = 'paid';
        }
        $isUpi = strtolower($payMethod) === 'upi_intent';
        $upiTxnId = trim((string) ($detail['upiTxnId'] ?? ''));
        $upiPayerVpa = trim((string) ($detail['upiPayerVpa'] ?? ''));
        $upiRef = trim((string) ($detail['upiTransactionRef'] ?? ''));
        $payVerification = trim((string) ($detail['paymentVerification'] ?? ''));
        $verifyNote = trim((string) ($detail['verificationNote'] ?? ''));
        $refundStatus = trim((string) ($detail['refundStatus'] ?? ''));
        $refundRef = trim((string) ($detail['refundRef'] ?? ''));
        $refundRequestedAt = $detail['refundRequestedAt'] ?? null;
        $serverAmount = $detail['serverAmount'] ?? null;
        $payStatusKey = strtolower($payStatus);
        $canReviewUpi = $isUpi && $payStatusKey !== 'paid' && $payStatusKey !== 'refunded';
        $canRefundUpi = $isUpi && $payStatusKey === 'paid';
        $keepFilters = [
            'filter_status' => $filter,
            'filter_outlet' => $outletFilter,
            'filter_q' => $searchQuery,
        ];
        if (trim((string) ($_GET['type'] ?? '')) !== '') {
            $keepFilters['filter_type'] = $typeFilter;
        }
        ?>
    <div class="modal fade" id="orderDetailModal" tabindex="-1" aria-hidden="true" data-bs-backdrop="true">
      <div class="modal-dialog modal-dialog-scrollable modal-lg">
        <div class="modal-content order-detail">
          <div class="modal-header">
                <div>
                    <h2 class="h5 mb-1"><?= brisko_h($detailId) ?></h2>
                    <span class="badge-status st-<?= brisko_h($st) ?>"><?= brisko_h(brisko_status_label($st)) ?></span>
                </div>
                <a class="btn-close" href="orders.php<?= $closeQuery !== '' ? ('?' . brisko_h($closeQuery)) : '' ?>" aria-label="Close"></a>
          </div>
          <div class="modal-body">
            <p class="mb-1"><strong>Placed:</strong> <?= brisko_h(brisko_dt($detail['createdAt'] ?? 0)) ?></p>
            <p class="mb-1"><strong>Type:</strong> <?= brisko_h($orderType) ?></p>
            <p class="mb-1"><strong>Customer:</strong> <?= brisko_h((string) ($customer['name'] ?? $uid)) ?></p>
            <p class="mb-1"><strong>Phone:</strong> <?= brisko_h((string) ($customer['phone'] ?? $customer['email'] ?? '-')) ?></p>
            <p class="mb-1"><strong>Receiver:</strong> <?= brisko_h($receiverName !== '' ? $receiverName : '-') ?><?= $receiverPhone !== '' ? (' · ' . brisko_h($receiverPhone)) : '' ?></p>
            <p class="mb-1"><strong>Outlet:</strong> <?= brisko_h($outletName) ?><?php if ($outletMapUrl !== ''): ?> — <a href="<?= brisko_h($outletMapUrl) ?>" target="_blank" rel="noopener">View on Google Maps</a><?php endif; ?></p>
            <p class="mb-1"><strong>Payment:</strong> <?= brisko_h(brisko_pretty_option($payMethod !== '' ? $payMethod : 'cod')) ?><?= $payStatus !== '' ? (' · ' . brisko_h(brisko_pretty_option($payStatus))) : '' ?></p>
            <?php if ($isUpi): ?>
                <p class="mb-1"><strong>UPI txn:</strong> <?= brisko_h($upiTxnId !== '' ? $upiTxnId : '-') ?><?= $upiPayerVpa !== '' ? (' · ' . brisko_h($upiPayerVpa)) : '' ?></p>
                <?php if ($upiRef !== ''): ?><p class="mb-1"><strong>UPI ref:</strong> <?= brisko_h($upiRef) ?></p><?php endif; ?>
                <p class="mb-1"><strong>Verification:</strong> <?= brisko_h($payVerification !== '' ? brisko_pretty_option($payVerification) : '-') ?><?= $serverAmount !== null ? (' · Server ' . brisko_h(brisko_money($serverAmount))) : '' ?></p>
                <?php if ($verifyNote !== ''): ?><p class="mb-1 small text-danger"><strong>Note:</strong> <?= brisko_h($verifyNote) ?></p><?php endif; ?>
                <?php if ($refundStatus !== ''): ?><p class="mb-1"><strong>Refund:</strong> <?= brisko_h(brisko_pretty_option($refundStatus)) ?><?= $refundRef !== '' ? (' · ' . brisko_h($refundRef)) : '' ?><?= !empty($detail['refundedAt']) ? (' · ' . brisko_h(brisko_dt($detail['refundedAt']))) : (!empty($refundRequestedAt) ? (' · requested ' . brisko_h(brisko_dt($refundRequestedAt))) : '') ?></p><?php endif; ?>
            <?php endif; ?>
            <p class="mb-1"><strong>Address:</strong> <?= brisko_h((string) ($addr['fullAddress'] ?? $addr['address'] ?? '-')) ?></p>
            <p class="mb-3"><strong>Notes:</strong> <?= brisko_h((string) ($detail['orderNotes'] ?? '-')) ?></p>
            <h3 class="h6">Ordered items</h3>
            <?php if ($items === []): ?>
                <p class="small text-muted">No line items on this order.</p>
            <?php else: ?>
            <ul class="list-unstyled order-items">
                <?php foreach ($items as $item):
                    $size = brisko_pretty_option((string) ($item['selectedSize'] ?? ''));
                    $crust = brisko_pretty_option((string) ($item['selectedCrust'] ?? ''));
                    $toppings = brisko_map_names($item['toppings'] ?? []);
                    $addons = brisko_map_names($item['addons'] ?? []);
                    ?>
                    <li class="order-item">
                        <div class="d-flex justify-content-between gap-2">
                            <span class="fw-semibold"><?= brisko_h((string) ($item['name'] ?? 'Item')) ?> x <?= (int) ($item['quantity'] ?? 1) ?></span>
                            <strong><?= brisko_h(brisko_money($item['totalPrice'] ?? 0)) ?></strong>
                        </div>
                        <div class="small text-muted">Unit <?= brisko_h(brisko_money($item['unitPrice'] ?? 0)) ?></div>
                        <?php if ($size !== ''): ?><div class="small">Size: <?= brisko_h($size) ?></div><?php endif; ?>
                        <?php if ($crust !== ''): ?><div class="small">Crust: <?= brisko_h($crust) ?></div><?php endif; ?>
                        <?php if ($toppings !== ''): ?><div class="small">Toppings: <?= brisko_h($toppings) ?></div><?php endif; ?>
                        <?php if ($addons !== ''): ?><div class="small">Addons: <?= brisko_h($addons) ?></div><?php endif; ?>
                    </li>
                <?php endforeach; ?>
            </ul>
            <?php endif; ?>
            <div class="price-box mt-3">
                <div>Subtotal <?= brisko_h(brisko_money($detail['subtotal'] ?? 0)) ?></div>
                <div>GST <?= brisko_h(brisko_money($detail['gstAmount'] ?? 0)) ?></div>
                <div>Delivery <?= brisko_h(brisko_money($detail['deliveryCharge'] ?? 0)) ?></div>
                <div>Coupon <?= brisko_h((string) ($detail['couponCode'] ?? '-')) ?> (-<?= brisko_h(brisko_money($detail['couponDiscount'] ?? 0)) ?>)</div>
                <div>Loyalty -<?= brisko_h(brisko_money($detail['loyaltyDiscount'] ?? 0)) ?></div>
                <div class="fw-bold">Final <?= brisko_h(brisko_money($detail['finalAmount'] ?? 0)) ?></div>
            </div>
            <div class="d-flex flex-wrap gap-2 mt-3">
                <?php $next = brisko_next_status($st); if ($next): ?>
                    <form method="post">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="status">
                        <input type="hidden" name="orderId" value="<?= brisko_h($detailId) ?>">
                        <input type="hidden" name="status" value="<?= brisko_h($next) ?>">
                        <?php if ($filter !== ''): ?><input type="hidden" name="filter_status" value="<?= brisko_h($filter) ?>"><?php endif; ?>
                        <?php if ($outletFilter !== ''): ?><input type="hidden" name="filter_outlet" value="<?= brisko_h($outletFilter) ?>"><?php endif; ?>
                                    <?php if ($searchQuery !== ''): ?><input type="hidden" name="filter_q" value="<?= brisko_h($searchQuery) ?>"><?php endif; ?>
                        <button class="btn btn-primary" type="submit">Mark <?= brisko_h(brisko_status_label($next)) ?></button>
                    </form>
                <?php endif; ?>
                <?php if ($st !== 'delivered' && $st !== 'cancelled'): ?>
                    <form method="post" onsubmit="return confirm('Cancel this order?')">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="status">
                        <input type="hidden" name="orderId" value="<?= brisko_h($detailId) ?>">
                        <input type="hidden" name="status" value="cancelled">
                        <?php if ($filter !== ''): ?><input type="hidden" name="filter_status" value="<?= brisko_h($filter) ?>"><?php endif; ?>
                        <?php if ($outletFilter !== ''): ?><input type="hidden" name="filter_outlet" value="<?= brisko_h($outletFilter) ?>"><?php endif; ?>
                                    <?php if ($searchQuery !== ''): ?><input type="hidden" name="filter_q" value="<?= brisko_h($searchQuery) ?>"><?php endif; ?>
                        <button class="btn btn-outline-danger" type="submit">Cancel</button>
                    </form>
                <?php endif; ?>
                <form method="post">
                    <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                    <input type="hidden" name="action" value="invoice">
                    <input type="hidden" name="orderId" value="<?= brisko_h($detailId) ?>">
                    <?php if ($filter !== ''): ?><input type="hidden" name="filter_status" value="<?= brisko_h($filter) ?>"><?php endif; ?>
                    <?php if ($outletFilter !== ''): ?><input type="hidden" name="filter_outlet" value="<?= brisko_h($outletFilter) ?>"><?php endif; ?>
                                    <?php if ($searchQuery !== ''): ?><input type="hidden" name="filter_q" value="<?= brisko_h($searchQuery) ?>"><?php endif; ?>
                    <button class="btn btn-outline-dark" type="submit">Generate invoice</button>
                </form>
                <?php if ($canReviewUpi): ?>
                    <form method="post" class="d-flex flex-wrap gap-2 align-items-center">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="upi_verify">
                        <input type="hidden" name="orderId" value="<?= brisko_h($detailId) ?>">
                        <?php foreach (array_filter($keepFilters) as $k => $v): ?><input type="hidden" name="<?= brisko_h((string) $k) ?>" value="<?= brisko_h((string) $v) ?>"><?php endforeach; ?>
                        <input type="text" class="form-control form-control-sm" name="note" placeholder="UPI ref / note (optional)" style="max-width: 220px;">
                        <button class="btn btn-success" type="submit" onclick="return confirm('Confirm this UPI payment was received?')">Mark UPI received</button>
                    </form>
                    <form method="post" onsubmit="return confirm('Mark this UPI payment as not received?')">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="upi_reject">
                        <input type="hidden" name="orderId" value="<?= brisko_h($detailId) ?>">
                        <?php foreach (array_filter($keepFilters) as $k => $v): ?><input type="hidden" name="<?= brisko_h((string) $k) ?>" value="<?= brisko_h((string) $v) ?>"><?php endforeach; ?>
                        <button class="btn btn-outline-warning" type="submit">Mark UPI not received</button>
                    </form>
                <?php endif; ?>
                <?php if ($canRefundUpi): ?>
                    <form method="post" class="d-flex flex-wrap gap-2 align-items-center" onsubmit="return confirm('Mark this paid UPI order as refunded?')">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="upi_refund">
                        <input type="hidden" name="orderId" value="<?= brisko_h($detailId) ?>">
                        <?php foreach (array_filter($keepFilters) as $k => $v): ?><input type="hidden" name="<?= brisko_h((string) $k) ?>" value="<?= brisko_h((string) $v) ?>"><?php endforeach; ?>
                        <input type="text" class="form-control form-control-sm" name="refundRef" placeholder="Refund ref / UTR" style="max-width: 220px;">
                        <button class="btn btn-outline-secondary" type="submit">Mark refunded</button>
                    </form>
                <?php endif; ?>
            </div>
            <?php if (!empty($detail['invoiceUrl'])): ?>
                <p class="mt-3 mb-0"><a href="<?= brisko_h((string) $detail['invoiceUrl']) ?>" target="_blank" rel="noopener">Open invoice</a></p>
            <?php endif; ?>
          </div>
        </div>
      </div>
    </div>
    <script>
    document.addEventListener('DOMContentLoaded', function () {
        var m = new bootstrap.Modal(document.getElementById('orderDetailModal'));
        m.show();
        document.getElementById('orderDetailModal').addEventListener('hidden.bs.modal', function () {
            window.location.href = <?= json_encode('orders.php' . ($closeQuery !== '' ? ('?' . $closeQuery) : '')) ?>;
        });
    });
    </script>
    <?php endif; ?>
<?php require __DIR__ . '/includes/footer.php'; ?>