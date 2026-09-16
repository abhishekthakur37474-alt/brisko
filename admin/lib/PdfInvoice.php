<?php

declare(strict_types=1);

class PdfInvoice
{
    public static function writeHtml(string $dir, string $orderId, array $order): string
    {
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        $file = rtrim($dir, '/') . '/' . preg_replace('/[^A-Za-z0-9_-]/', '', $orderId) . '.html';
        $items = $order['items'] ?? [];
        if ($items instanceof stdClass) {
            $items = [];
        }
        if (is_array($items) && $items !== [] && array_is_list($items) === false) {
            ksort($items);
            $items = array_values($items);
        }
        $rows = '';
        foreach ((array) $items as $item) {
            if (!is_array($item)) {
                continue;
            }
            $name = htmlspecialchars((string) ($item['name'] ?? 'Item'), ENT_QUOTES, 'UTF-8');
            $qty = (int) ($item['quantity'] ?? 1);
            $unit = number_format((float) ($item['unitPrice'] ?? 0), 2);
            $total = number_format((float) ($item['totalPrice'] ?? 0), 2);
            $rows .= "<tr><td>{$name}</td><td>{$qty}</td><td>Rs {$unit}</td><td>Rs {$total}</td></tr>";
        }
        $addr = $order['addressSnapshot'] ?? [];
        $address = htmlspecialchars((string) ($addr['fullAddress'] ?? ''), ENT_QUOTES, 'UTF-8');
        $receiverName = htmlspecialchars((string) ($order['receiverName'] ?? ''), ENT_QUOTES, 'UTF-8');
        $receiverPhone = htmlspecialchars((string) ($addr['receiverPhone'] ?? ($order['receiverPhone'] ?? '')), ENT_QUOTES, 'UTF-8');
        $orderType = htmlspecialchars(ucwords(str_replace('_', ' ', (string) ($order['orderType'] ?? 'delivery'))), ENT_QUOTES, 'UTF-8');
        $created = isset($order['createdAt']) ? date('d M Y, h:i A', (int) ((int) $order['createdAt'] / 1000)) : '';
        $paymentLine = htmlspecialchars((string) ($order['paymentMethod'] ?? 'cod'), ENT_QUOTES, 'UTF-8')
            . ' / ' . htmlspecialchars((string) ($order['paymentStatus'] ?? ''), ENT_QUOTES, 'UTF-8');
        $upiTxnId = trim((string) ($order['upiTxnId'] ?? ''));
        if ($upiTxnId !== '') {
            $paymentLine .= '<br><strong>UPI txn:</strong> ' . htmlspecialchars($upiTxnId, ENT_QUOTES, 'UTF-8');
        }
        $refundStatus = trim((string) ($order['refundStatus'] ?? ''));
        if ($refundStatus !== '') {
            $refundRef = trim((string) ($order['refundRef'] ?? ''));
            $paymentLine .= '<br><strong>Refund:</strong> ' . htmlspecialchars($refundStatus, ENT_QUOTES, 'UTF-8')
                . ($refundRef !== '' ? (' · ' . htmlspecialchars($refundRef, ENT_QUOTES, 'UTF-8')) : '');
        }
        $html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Invoice ' . htmlspecialchars($orderId) . '</title>
<style>
body{font-family:Arial,sans-serif;color:#111;margin:32px}
h1{color:#E30613;margin:0}
.muted{color:#666}
table{width:100%;border-collapse:collapse;margin-top:18px}
th,td{border-bottom:1px solid #eee;padding:8px;text-align:left}
.tot{font-weight:700}
</style></head><body>
<h1>Brisko Pizza</h1>
<p class="muted">Hot. Fresh. Fast.</p>
<p><strong>Invoice:</strong> ' . htmlspecialchars($orderId) . '<br>
<strong>Date:</strong> ' . htmlspecialchars($created) . '<br>
<strong>Payment:</strong> ' . $paymentLine . '<br>
<strong>Type:</strong> ' . $orderType . '</p>
<p><strong>Receiver:</strong> ' . $receiverName . ($receiverPhone !== '' ? (' (' . $receiverPhone . ')') : '') . '<br>
<strong>Address</strong><br>' . $address . '</p>
<table><thead><tr><th>Item</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead><tbody>' . $rows . '</tbody></table>
<p>Subtotal: Rs ' . number_format((float) ($order['subtotal'] ?? 0), 2) . '<br>
GST: Rs ' . number_format((float) ($order['gstAmount'] ?? 0), 2) . '<br>
Delivery: Rs ' . number_format((float) ($order['deliveryCharge'] ?? 0), 2) . '<br>
Coupon: - Rs ' . number_format((float) ($order['couponDiscount'] ?? 0), 2) . '<br>
Loyalty: - Rs ' . number_format((float) ($order['loyaltyDiscount'] ?? 0), 2) . '<br>
<span class="tot">Final: Rs ' . number_format((float) ($order['finalAmount'] ?? 0), 2) . '</span></p>
</body></html>';
        file_put_contents($file, $html);
        return $file;
    }
}
