<?php

declare(strict_types=1);

require_once __DIR__ . '/firebase_service.php';
require_once __DIR__ . '/order_service.php';

/**
 * Server-side UPI Intent payment verification.
 *
 * UPI Intent (`upi://pay`) is settled directly between the customer's UPI app
 * and the merchant VPA, so the Flutter app can never be trusted to declare a
 * payment as received. This service is the ONLY component that may flip a UPI
 * order to `paid`:
 *
 *   1. it recomputes the payable amount from the RTDB catalog and rejects any
 *      order whose stored amount does not match (tamper detection);
 *   2. it optionally asks an external verifier (UPI_VERIFY_URL) to confirm the
 *      transaction id/amount before marking it paid;
 *   3. when no verifier is configured the order stays `pending` and an admin
 *      reconciles it against the bank statement.
 */
class UpiPaymentService
{
    private FirebaseService $fb;
    private OrderService $orders;

    /** @var array<string, mixed> */
    private array $config;

    /** @param array<string, mixed> $config */
    public function __construct(FirebaseService $fb, OrderService $orders, array $config)
    {
        $this->fb = $fb;
        $this->orders = $orders;
        $this->config = $config;
    }

    /**
     * Verifies a UPI Intent payment for an order the app already created.
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    public function verify(string $uid, array $payload): array
    {
        $orderId = trim((string) ($payload['orderId'] ?? ''));
        if ($orderId === '' || !preg_match('/^[A-Za-z0-9_-]{4,64}$/', $orderId)) {
            throw new ApiException('A valid order id is required.', 400);
        }

        $order = $this->fb->get('orders/' . $orderId);
        if (!is_array($order)) {
            throw new ApiException('Order not found.', 404);
        }
        if ((string) ($order['userId'] ?? '') !== $uid) {
            throw new ApiException('You are not allowed to verify this order.', 403);
        }
        if (strtolower((string) ($order['paymentMethod'] ?? '')) !== 'upi_intent') {
            throw new ApiException('This order is not a UPI Intent payment.', 400);
        }

        $current = strtolower((string) ($order['paymentStatus'] ?? 'pending'));
        if ($current === 'paid') {
            return [
                'order_id' => $orderId,
                'paymentStatus' => 'paid',
                'verification' => (string) ($order['paymentVerification'] ?? 'verified'),
                'amount' => (float) ($order['finalAmount'] ?? 0),
                'message' => 'Payment already confirmed.',
            ];
        }

        $now = (int) round(microtime(true) * 1000);

        // Record the UPI app's transaction details regardless of the outcome so
        // they are available for reconciliation.
        $patch = [
            'upiTxnId' => $this->cleanRef($payload['upiTxnId'] ?? ''),
            'upiResponseCode' => $this->cleanRef($payload['upiResponseCode'] ?? ''),
            'upiPayerVpa' => $this->cleanRef($payload['upiPayerVpa'] ?? ''),
            'upiTransactionRef' => $this->cleanRef($payload['transactionRef'] ?? ''),
            'updatedAt' => $now,
        ];

        $check = $this->reconcileAmount($uid, $order, $payload);

        if ($check['mismatch']) {
            $patch['paymentStatus'] = 'pending';
            $patch['paymentVerification'] = 'rejected';
            $patch['verificationNote'] = $check['note'];
            $this->fb->ref('orders/' . $orderId)->update($patch);
            error_log('[brisko] upi amount mismatch for ' . $orderId . ': ' . $check['note']);
            return [
                'order_id' => $orderId,
                'paymentStatus' => 'pending',
                'verification' => 'rejected',
                'amount' => (float) ($order['finalAmount'] ?? 0),
                'message' => 'We could not match the paid amount to this order. It needs manual review.',
            ];
        }

        $patch['serverAmount'] = $check['expectedAmount'];

        $verifyUrl = trim((string) ($this->config['verify_url'] ?? ''));
        if ($verifyUrl === '') {
            $patch['paymentStatus'] = 'pending';
            $patch['paymentVerification'] = 'pending';
            $this->fb->ref('orders/' . $orderId)->update($patch);
            return [
                'order_id' => $orderId,
                'paymentStatus' => 'pending',
                'verification' => 'pending',
                'amount' => $check['expectedAmount'],
                'message' => 'Your payment is being confirmed. This usually takes a few minutes.',
            ];
        }

        $result = $this->callVerifier($verifyUrl, $orderId, $check['expectedAmount'], $payload);

        if ($result['verified'] === true) {
            $patch['paymentStatus'] = 'paid';
            $patch['paymentVerification'] = 'verified';
            $patch['paymentVerifiedAt'] = $now;
            $patch['paidAt'] = $now;
            if ($result['reference'] !== '') {
                $patch['upiTxnId'] = $result['reference'];
            }
            if ($result['payerVpa'] !== '') {
                $patch['upiPayerVpa'] = $result['payerVpa'];
            }
            $this->fb->ref('orders/' . $orderId)->update($patch);
            return [
                'order_id' => $orderId,
                'paymentStatus' => 'paid',
                'verification' => 'verified',
                'amount' => $check['expectedAmount'],
                'message' => 'Payment confirmed.',
            ];
        }

        if ($result['verified'] === false) {
            $patch['paymentStatus'] = 'pending';
            $patch['paymentVerification'] = 'rejected';
            $patch['verificationNote'] = $result['note'] !== '' ? $result['note'] : 'verification_failed';
            $this->fb->ref('orders/' . $orderId)->update($patch);
            return [
                'order_id' => $orderId,
                'paymentStatus' => 'pending',
                'verification' => 'rejected',
                'amount' => $check['expectedAmount'],
                'message' => 'We could not verify this payment. It needs manual review.',
            ];
        }

        $patch['paymentStatus'] = 'pending';
        $patch['paymentVerification'] = 'pending';
        $this->fb->ref('orders/' . $orderId)->update($patch);
        return [
            'order_id' => $orderId,
            'paymentStatus' => 'pending',
            'verification' => 'pending',
            'amount' => $check['expectedAmount'],
            'message' => 'Your payment is being confirmed. This usually takes a few minutes.',
        ];
    }

    /**
     * Recomputes the order total from the RTDB catalog and compares it with the
     * stored (client-written) amounts.
     *
     * @param array<string, mixed> $order
     * @param array<string, mixed> $payload
     * @return array{mismatch: bool, expectedAmount: float, note: string}
     */
    private function reconcileAmount(string $uid, array $order, array $payload): array
    {
        $items = [];
        $rawItems = $order['items'] ?? [];
        if (is_array($rawItems)) {
            foreach ($rawItems as $row) {
                if (is_array($row)) {
                    $items[] = $row;
                }
            }
        }

        $storeSubtotal = (float) ($order['subtotal'] ?? 0);
        $storeGst = (float) ($order['gstAmount'] ?? 0);
        $storeDelivery = (float) ($order['deliveryCharge'] ?? 0);
        $storeCoupon = (float) ($order['couponDiscount'] ?? 0);
        $storeLoyalty = (float) ($order['loyaltyDiscount'] ?? 0);
        $storeFinal = (float) ($order['finalAmount'] ?? 0);

        $notes = [];

        try {
            $base = $this->orders->computeItemsPricing([
                'items' => $items,
                'orderMode' => (string) ($order['orderType'] ?? 'delivery'),
            ]);
        } catch (\Throwable $e) {
            return [
                'mismatch' => true,
                'expectedAmount' => $storeFinal,
                'note' => 'catalog_recompute_failed: ' . $e->getMessage(),
            ];
        }

        $mismatch = abs($base['subtotal'] - $storeSubtotal) > 0.01
            || abs($base['gstAmount'] - $storeGst) > 0.01
            || abs($base['deliveryCharge'] - $storeDelivery) > 0.01;

        $couponDiscount = $storeCoupon;
        $code = strtoupper(trim((string) ($order['couponCode'] ?? '')));
        if ($code !== '') {
            try {
                $coupon = $this->orders->resolveCoupon($uid, $code, $base['subtotal']);
                $couponDiscount = (float) $coupon['discount'];
            } catch (\Throwable $e) {
                $notes[] = 'coupon_recheck_failed';
            }
        } elseif ($storeCoupon > 0) {
            $notes[] = 'unexpected_coupon_discount';
            $mismatch = true;
        }

        $loyaltyDiscount = $storeLoyalty;
        if ((int) ($order['loyaltyPointsUsed'] ?? 0) > 0) {
            try {
                $loyalty = $this->orders->resolveLoyalty(
                    $uid,
                    true,
                    $base['subtotal'] + $base['gstAmount'] + $base['deliveryCharge'] - $couponDiscount
                );
                $loyaltyDiscount = (float) $loyalty['discount'];
            } catch (\Throwable $e) {
                $notes[] = 'loyalty_recheck_failed';
            }
        } elseif ($storeLoyalty > 0) {
            $notes[] = 'unexpected_loyalty_discount';
            $mismatch = true;
        }

        $expected = $base['subtotal'] + $base['gstAmount'] + $base['deliveryCharge'] - $couponDiscount - $loyaltyDiscount;
        if ($expected < 0) {
            $expected = 0.0;
        }
        $expected = round($expected, 2);

        if (abs($expected - $storeFinal) > 0.01) {
            $mismatch = true;
            $notes[] = 'final_mismatch(' . number_format($expected, 2) . '!=' . number_format($storeFinal, 2) . ')';
        }

        $clientAmount = $payload['amount'] ?? null;
        if ($clientAmount !== null && $clientAmount !== '') {
            $clientAmount = (float) $clientAmount;
            if (abs($clientAmount - $storeFinal) > 0.01) {
                $mismatch = true;
                $notes[] = 'client_amount_mismatch';
            }
        }

        return [
            'mismatch' => $mismatch,
            'expectedAmount' => $expected,
            'note' => $notes === [] ? '' : implode(', ', $notes),
        ];
    }

    /**
     * Asks the configured external verifier to confirm a UPI transaction.
     *
     * @param array<string, mixed> $payload
     * @return array{verified: ?bool, reference: string, payerVpa: string, note: string}
     */
    private function callVerifier(string $url, string $orderId, float $amount, array $payload): array
    {
        $body = json_encode([
            'orderId' => $orderId,
            'amount' => $amount,
            'txnId' => (string) ($payload['upiTxnId'] ?? ''),
            'responseCode' => (string) ($payload['upiResponseCode'] ?? ''),
            'transactionRef' => (string) ($payload['transactionRef'] ?? ''),
            'payerVpa' => (string) ($payload['upiPayerVpa'] ?? ''),
            'merchantVpa' => (string) ($this->config['merchant_vpa'] ?? ''),
        ]);

        $timeout = max(3, (int) ($this->config['verify_timeout'] ?? 15));
        $headers = ['Content-Type: application/json', 'Accept: application/json'];
        $secret = (string) ($this->config['verify_secret'] ?? '');
        if ($secret !== '') {
            $headers[] = 'X-Verify-Secret: ' . $secret;
        }

        $ch = curl_init($url);
        if ($ch === false) {
            return ['verified' => null, 'reference' => '', 'payerVpa' => '', 'note' => 'verifier_unreachable'];
        }
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_TIMEOUT => $timeout,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_POSTFIELDS => is_string($body) ? $body : '{}',
        ]);
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $code >= 400) {
            error_log('[brisko] upi verifier failed for ' . $orderId . ': ' . ($err !== '' ? $err : ('HTTP ' . $code)));
            return ['verified' => null, 'reference' => '', 'payerVpa' => '', 'note' => 'verifier_unreachable'];
        }

        $decoded = json_decode((string) $raw, true);
        if (!is_array($decoded)) {
            return ['verified' => null, 'reference' => '', 'payerVpa' => '', 'note' => 'verifier_bad_response'];
        }

        $verified = $decoded['verified'] ?? null;
        if ($verified === true || $verified === 'true' || $verified === 1 || $verified === '1') {
            return [
                'verified' => true,
                'reference' => $this->cleanRef($decoded['reference'] ?? ($decoded['txnId'] ?? '')),
                'payerVpa' => $this->cleanRef($decoded['payerVpa'] ?? ''),
                'note' => '',
            ];
        }
        if ($verified === false || $verified === 'false' || $verified === 0 || $verified === '0') {
            return [
                'verified' => false,
                'reference' => '',
                'payerVpa' => '',
                'note' => $this->cleanRef($decoded['reason'] ?? '') ?: 'verification_failed',
            ];
        }

        return ['verified' => null, 'reference' => '', 'payerVpa' => '', 'note' => 'verification_pending'];
    }

    private function cleanRef(mixed $value): string
    {
        $value = preg_replace('/[^A-Za-z0-9.@_\/-]/', '', trim((string) $value));
        return substr(is_string($value) ? $value : '', 0, 80);
    }
}
