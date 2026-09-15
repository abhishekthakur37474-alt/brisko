    <?php

    declare(strict_types=1);

    /**
     * Server-side order + payment service for the Cashfree online flow.
     *
     * The server is the single source of truth for:
     *   - the payable amount (recomputed from the RTDB product catalog)
     *   - the merchant order id (generated here, never chosen by the client)
     *   - the payment status (only ever changed after a Cashfree confirmation)
     *
     * Flutter sends the cart; it never sends a trusted amount. The order record is
     * written to the same `orders/{orderId}` node the app already uses, so existing
     * order screens keep working unchanged.
     */
    class OrderService
    {
        private FirebaseService $fb;

        /** @var array<string, mixed> */
        private array $pricing;

        /** @param array<string, mixed> $pricing */
        public function __construct(FirebaseService $fb, array $pricing)
        {
            $this->fb = $fb;
            $this->pricing = $pricing;
        }

        public function getLocalOrder(string $orderId): ?array
        {
            $order = $this->fb->get('orders/' . $orderId);
            return is_array($order) ? $order : null;
        }

        /**
         * Creates the Cashfree order and the matching PENDING record in RTDB.
         *
         * @param array<string, mixed> $payload
         * @param array<string, mixed> $cashfreeConfig
         * @return array<string, mixed>
         */
        public function createOnlineOrder(string $uid, array $payload, CashfreeService $cashfree, array $cashfreeConfig): array
        {
            $base = $this->computeItemsPricing($payload);

            $currency = strtoupper(trim((string) ($payload['currency'] ?? 'INR')));
            if ($currency === '') {
                $currency = 'INR';
            }
            $allowed = $cashfreeConfig['allowed_currencies'] ?? ['INR'];
            if (!is_array($allowed) || !in_array($currency, $allowed, true)) {
                throw new ApiException('Unsupported currency.', 400);
            }

            $coupon = $this->resolveCoupon($uid, (string) ($payload['couponCode'] ?? ''), $base['subtotal']);

            $preLoyalty = $base['subtotal'] + $base['gstAmount'] + $base['deliveryCharge'] - $coupon['discount'];
            $loyalty = $this->resolveLoyalty($uid, ($payload['redeemLoyalty'] ?? false) === true, $preLoyalty);

            $finalAmount = $base['subtotal'] + $base['gstAmount'] + $base['deliveryCharge']
                - $coupon['discount'] - $loyalty['discount'];
            if ($finalAmount < 0) {
                $finalAmount = 0.0;
            }
            $finalAmount = round($finalAmount, 2);

            $maxAmount = (float) ($this->pricing['max_order_amount'] ?? 50000.0);
            if ($finalAmount < 1.0) {
                throw new ApiException('The payable amount is too low for online payment.', 400);
            }
            if ($finalAmount > $maxAmount) {
                throw new ApiException('This order exceeds the online payment limit.', 400);
            }

            $user = $this->fb->get('users/' . $uid);
            $user = is_array($user) ? $user : [];

            $receiverName = trim((string) ($payload['receiverName'] ?? ''));
            if ($receiverName === '') {
                $receiverName = trim((string) ($user['name'] ?? ''));
            }

            $receiverPhone = trim((string) ($payload['receiverPhone'] ?? ''));
            if ($receiverPhone === '') {
                $receiverPhone = trim((string) ($user['phone'] ?? ''));
            }
            if ($receiverPhone === '') {
                $receiverPhone = $uid;
            }

            $customerPhone = $this->formatPhone($receiverPhone);
            if ($customerPhone === '') {
                throw new ApiException('A valid phone number is required to pay online.', 400);
            }

            $orderMode = (string) ($payload['orderMode'] ?? 'delivery');
            if (!in_array($orderMode, ['delivery', 'takeaway', 'dineIn'], true)) {
                $orderMode = 'delivery';
            }

            $address = $payload['address'] ?? [];
            if (!is_array($address)) {
                $address = [];
            }
            $address['receiverName'] = $receiverName;
            $address['receiverPhone'] = $receiverPhone;

            $outletId = trim((string) ($payload['outletId'] ?? ''));
            $orderNotes = trim((string) ($payload['notes'] ?? ''));

            $orderId = $this->generateOrderId();

            $orderRequest = [
                'order_id' => $orderId,
                'order_amount' => $finalAmount,
                'order_currency' => $currency,
                'order_note' => 'Brisko order ' . $orderId,
                'customer_details' => array_filter([
                    'customer_id' => $uid,
                    'customer_name' => $receiverName,
                    'customer_email' => trim((string) ($user['email'] ?? '')),
                    'customer_phone' => $customerPhone,
                ], static fn ($value): bool => $value !== '' && $value !== null),
            ];

            $returnUrl = trim((string) ($cashfreeConfig['return_url'] ?? ''));
            if ($returnUrl !== '') {
                $orderRequest['order_meta'] = ['return_url' => $returnUrl];
            }

            $cfOrder = $cashfree->createOrder($orderRequest);

            $paymentSessionId = (string) ($cfOrder['payment_session_id'] ?? '');
            if ($paymentSessionId === '') {
                error_log('[brisko] cashfree order created without payment_session_id for ' . $orderId);
                throw new ApiException('Unable to start the payment session. Please try again.', 502);
            }

            $now = (int) round(microtime(true) * 1000);
            $cfOrderStatus = strtoupper((string) ($cfOrder['order_status'] ?? 'ACTIVE'));

            $itemsMap = [];
            foreach ($base['items'] as $index => $item) {
                $itemsMap[(string) $index] = $item;
            }

            $order = [
                // Fields required by STEP 5 of the integration spec.
                'orderId' => $orderId,
                'amount' => $finalAmount,
                'currency' => $currency,
                'paymentStatus' => 'PENDING',
                'cashfreeOrderStatus' => $cfOrderStatus,
                'paymentSessionId' => $paymentSessionId,
                'paidAt' => null,
                // Fields consumed by the existing Flutter OrderModel.
                'userId' => $uid,
                'outletId' => $outletId,
                'items' => $itemsMap,
                'addressSnapshot' => $address,
                'subtotal' => $base['subtotal'],
                'gstAmount' => $base['gstAmount'],
                'deliveryCharge' => $base['deliveryCharge'],
                'couponCode' => $coupon['code'],
                'couponDiscount' => $coupon['discount'],
                'loyaltyPointsUsed' => $loyalty['points'],
                'loyaltyDiscount' => $loyalty['discount'],
                'finalAmount' => $finalAmount,
                'paymentMethod' => 'online',
                'orderStatus' => 'placed',
                'statusTimestamps' => ['placed' => $now],
                'orderNotes' => $orderNotes,
                'createdAt' => $now,
                'updatedAt' => $now,
                'invoiceUrl' => null,
                'receiverName' => $receiverName,
                'receiverPhone' => $receiverPhone,
                'orderType' => $orderMode,
            ];

            $updates = [
                'orders/' . $orderId => $order,
                'userOrders/' . $uid . '/' . $orderId => true,
            ];
            if ($outletId !== '') {
                $updates['outletOrders/' . $outletId . '/' . $orderId] = true;
            }

            $this->fb->ref('/')->update($updates);

            return [
                'order_id' => $orderId,
                'payment_session_id' => $paymentSessionId,
                'amount' => $finalAmount,
                'currency' => $currency,
                'order_status' => $cfOrderStatus,
            ];
        }

        /**
         * Resolves the current, server-authoritative Cashfree status for an order.
         *
         * @return array{paymentStatus: string, cashfreeOrderStatus: string}
         */
        public function resolveCashfreeStatus(string $orderId, CashfreeService $cashfree): array
        {
            $cfOrder = $cashfree->getOrder($orderId);
            $orderStatus = strtoupper((string) ($cfOrder['order_status'] ?? ''));

            if ($orderStatus === 'PAID') {
                return ['paymentStatus' => 'PAID', 'cashfreeOrderStatus' => 'PAID'];
            }

            $payments = [];
            try {
                $payments = $cashfree->getOrderPayments($orderId);
            } catch (\Throwable $e) {
                // Non-fatal: fall back to the order status below.
                error_log('[brisko] cashfree payments lookup failed for ' . $orderId . ': ' . $e->getMessage());
            }

            $lastPaymentStatus = '';
            foreach ($payments as $payment) {
                $status = strtoupper((string) ($payment['payment_status'] ?? ''));
                if ($status === 'SUCCESS') {
                    return [
                        'paymentStatus' => 'PAID',
                        'cashfreeOrderStatus' => $orderStatus !== '' ? $orderStatus : 'PAID',
                    ];
                }
                if ($status !== '') {
                    $lastPaymentStatus = $status;
                }
            }

            $map = [
                'FAILED' => 'FAILED',
                'USER_DROPPED' => 'USER_DROPPED',
                'CANCELLED' => 'FAILED',
                'VOID' => 'FAILED',
                'EXPIRED' => 'FAILED',
                'PENDING' => 'PENDING',
                'NOT_ATTEMPTED' => 'PENDING',
                'FLAGGED' => 'PENDING',
            ];

            if ($lastPaymentStatus !== '' && isset($map[$lastPaymentStatus])) {
                return [
                    'paymentStatus' => $map[$lastPaymentStatus],
                    'cashfreeOrderStatus' => $orderStatus !== '' ? $orderStatus : $lastPaymentStatus,
                ];
            }

            if ($orderStatus === 'EXPIRED') {
                return ['paymentStatus' => 'FAILED', 'cashfreeOrderStatus' => 'EXPIRED'];
            }
            if ($orderStatus === 'ACTIVE') {
                return ['paymentStatus' => 'PENDING', 'cashfreeOrderStatus' => 'ACTIVE'];
            }

            return [
                'paymentStatus' => $orderStatus !== '' ? $orderStatus : 'PENDING',
                'cashfreeOrderStatus' => $orderStatus,
            ];
        }

        /**
         * Idempotently updates the payment fields of an order.
         *
         * @param array<string, mixed> $order
         * @return array<string, mixed>
         */
        public function markOrderStatus(string $orderId, string $paymentStatus, string $cfOrderStatus, array $order): array
        {
            $now = (int) round(microtime(true) * 1000);

            $updates = [
                'paymentStatus' => $paymentStatus,
                'cashfreeOrderStatus' => $cfOrderStatus,
                'updatedAt' => $now,
            ];

            if ($paymentStatus === 'PAID' && empty($order['paidAt'])) {
                $updates['paidAt'] = $now;
            }

            $this->fb->ref('orders/' . $orderId)->update($updates);

            // Track per-user coupon usage once, keyed by order id so repeated
            // webhooks / verifications can never double count.
            if ($paymentStatus === 'PAID') {
                $uid = (string) ($order['userId'] ?? '');
                $code = strtoupper(trim((string) ($order['couponCode'] ?? '')));
                if ($uid !== '' && $code !== '') {
                    $this->fb->ref('users/' . $uid . '/couponUsage/' . $code . '/' . $orderId)->set(true);
                }
            }

            return $updates;
        }

        /**
         * Recomputes the cart total from the RTDB product catalog. This is the only
         * amount that is ever sent to Cashfree.
         *
         * @param array<string, mixed> $payload
         * @return array{items: array<int, array<string, mixed>>, subtotal: float, gstAmount: float, deliveryCharge: float}
         */
        public function computeItemsPricing(array $payload): array
        {
            $rawItems = $payload['items'] ?? null;
            if (!is_array($rawItems) || $rawItems === []) {
                throw new ApiException('Your cart is empty.', 400);
            }
            if (count($rawItems) > 50) {
                throw new ApiException('Too many items in this order.', 400);
            }

            $isPickup = ((string) ($payload['orderMode'] ?? 'delivery')) !== 'delivery';

            $subtotal = 0.0;
            $items = [];

            foreach ($rawItems as $raw) {
                if (!is_array($raw)) {
                    throw new ApiException('One of the cart items is invalid.', 400);
                }

                $productId = trim((string) ($raw['productId'] ?? ''));
                $quantity = (int) ($raw['quantity'] ?? 0);

                if ($productId === '' || $quantity < 1 || $quantity > 50) {
                    throw new ApiException('One of the cart items is invalid.', 400);
                }

                $product = $this->fb->get('products/' . $productId);
                if (!is_array($product)) {
                    throw new ApiException('One of the items in your cart is no longer available.', 400);
                }

                $unitPrice = $this->computeUnitPrice($product, $raw);
                $totalPrice = round($unitPrice * $quantity, 2);
                $subtotal += $totalPrice;

                $items[] = [
                    'productId' => $productId,
                    'name' => (string) ($product['name'] ?? ''),
                    'image' => $this->firstImage($product),
                    'selectedSize' => (string) ($raw['selectedSize'] ?? ''),
                    'selectedCrust' => (string) ($raw['selectedCrust'] ?? ''),
                    'toppings' => $this->selectedOptionPrices($product, 'toppings', $raw['toppings'] ?? []),
                    'addons' => $this->selectedOptionPrices($product, 'addons', $raw['addons'] ?? []),
                    'quantity' => $quantity,
                    'unitPrice' => round($unitPrice, 2),
                    'totalPrice' => $totalPrice,
                    'isVeg' => ($product['isVeg'] ?? true) !== false,
                ];
            }

            $subtotal = round($subtotal, 2);

            $gstRate = (float) ($this->pricing['gst_rate'] ?? 0.05);
            $freeThreshold = (float) ($this->pricing['free_delivery_threshold'] ?? 499.0);
            $deliveryFee = (float) ($this->pricing['flat_delivery_fee'] ?? 40.0);

            $gstAmount = round($subtotal * $gstRate, 2);
            $deliveryCharge = $isPickup ? 0.0 : ($subtotal >= $freeThreshold ? 0.0 : round($deliveryFee, 2));

            return [
                'items' => $items,
                'subtotal' => $subtotal,
                'gstAmount' => $gstAmount,
                'deliveryCharge' => $deliveryCharge,
            ];
        }

        /**
         * @param array<string, mixed> $product
         * @param array<string, mixed> $raw
         */
        private function computeUnitPrice(array $product, array $raw): float
        {
            $unit = (float) ($product['basePrice'] ?? 0);

            $size = trim((string) ($raw['selectedSize'] ?? ''));
            if ($size !== '') {
                $unit += $this->optionPrice($product, 'sizes', $size);
            }

            $crust = trim((string) ($raw['selectedCrust'] ?? ''));
            if ($crust !== '') {
                $unit += $this->optionPrice($product, 'crusts', $crust);
            }

            foreach ($this->normalizeIds($raw['toppings'] ?? []) as $id) {
                $unit += $this->optionPrice($product, 'toppings', $id);
            }

            foreach ($this->normalizeIds($raw['addons'] ?? []) as $id) {
                $unit += $this->optionPrice($product, 'addons', $id);
            }

            return round($unit, 2);
        }

        /**
         * @param array<string, mixed> $product
         * @return array<string, float>
         */
        private function selectedOptionPrices(array $product, string $group, mixed $value): array
        {
            $prices = [];
            foreach ($this->normalizeIds($value) as $id) {
                $prices[$id] = $this->optionPrice($product, $group, $id);
            }
            return $prices;
        }

        /**
         * @param array<string, mixed> $product
         */
        private function optionPrice(array $product, string $group, string $id): float
        {
            $customizations = $product['customizations'] ?? null;
            $options = (is_array($customizations) && is_array($customizations[$group] ?? null))
                ? $customizations[$group]
                : [];

            if (!array_key_exists($id, $options) || !is_array($options[$id])) {
                throw new ApiException('One of the selected options is no longer available.', 400);
            }

            return (float) ($options[$id]['price'] ?? 0);
        }

        /**
         * Accepts either a list of ids (`["mushroom"]`) or a map (`{"mushroom": true}`)
         * and returns a clean list of ids.
         *
         * @return list<string>
         */
        private function normalizeIds(mixed $value): array
        {
            if (!is_array($value)) {
                return [];
            }

            $ids = [];
            foreach ($value as $key => $item) {
                $id = is_string($key) ? $key : (is_string($item) ? $item : '');
                $id = trim($id);
                if ($id !== '') {
                    $ids[] = $id;
                }
            }

            return array_values(array_unique($ids));
        }

        /**
         * @param array<string, mixed> $product
         */
        private function firstImage(array $product): string
        {
            $images = $product['images'] ?? null;
            if (is_array($images)) {
                foreach ($images as $image) {
                    if (is_string($image) && $image !== '') {
                        return $image;
                    }
                }
            }
            return '';
        }

        /**
         * @return array{code: ?string, discount: float}
         */
        public function resolveCoupon(string $uid, string $code, float $subtotal): array
        {
            $code = strtoupper(trim($code));
            if ($code === '') {
                return ['code' => null, 'discount' => 0.0];
            }

            $coupon = $this->fb->get('coupons/' . $code);
            if (!is_array($coupon) || ($coupon['isActive'] ?? true) === false) {
                throw new ApiException('This coupon is not valid.', 400);
            }

            $now = (int) round(microtime(true) * 1000);
            $validFrom = (int) ($coupon['validFrom'] ?? 0);
            $validTo = (int) ($coupon['validTo'] ?? 0);
            if (($validFrom > 0 && $now < $validFrom) || ($validTo > 0 && $now > $validTo)) {
                throw new ApiException('This coupon has expired.', 400);
            }

            $minOrder = (float) ($coupon['minOrderValue'] ?? 0);
            if ($subtotal < $minOrder) {
                throw new ApiException('This coupon needs a minimum order of Rs ' . number_format($minOrder, 0), 400);
            }

            if (($coupon['isFirstOrderOnly'] ?? false) === true) {
                $userOrders = $this->fb->get('userOrders/' . $uid);
                $orderCount = is_array($userOrders) ? count($userOrders) : 0;
                if ($orderCount > 0) {
                    throw new ApiException('This coupon is valid on your first order only.', 400);
                }
            }

            $limit = (int) ($coupon['usageLimitPerUser'] ?? 99);
            $usage = $this->fb->get('users/' . $uid . '/couponUsage/' . $code);
            $usedCount = is_array($usage) ? count($usage) : 0;
            if ($limit > 0 && $usedCount >= $limit) {
                throw new ApiException('You have already used this coupon.', 400);
            }

            $type = (string) ($coupon['discountType'] ?? 'flat');
            $value = (float) ($coupon['discountValue'] ?? 0);
            $discount = $type === 'percent' ? $subtotal * ($value / 100) : $value;

            $maxDiscount = (float) ($coupon['maxDiscount'] ?? 0);
            if ($maxDiscount > 0 && $discount > $maxDiscount) {
                $discount = $maxDiscount;
            }
            if ($discount > $subtotal) {
                $discount = $subtotal;
            }

            return ['code' => $code, 'discount' => round(max(0.0, $discount), 2)];
        }

        /**
         * @return array{points: int, discount: float}
         */
        public function resolveLoyalty(string $uid, bool $redeem, float $base): array
        {
            if (!$redeem) {
                return ['points' => 0, 'discount' => 0.0];
            }

            $config = $this->fb->get('loyaltyConfig');
            $config = is_array($config) ? $config : [];

            $rate = (float) ($config['redemptionValuePerPoint'] ?? 1.0);
            $minPoints = (int) ($config['minPointsToRedeem'] ?? 50);
            $maxPerOrder = (int) ($config['maxPointsUsablePerOrder'] ?? 200);
            if ($rate <= 0) {
                return ['points' => 0, 'discount' => 0.0];
            }

            $user = $this->fb->get('users/' . $uid);
            $available = is_array($user) ? (int) ($user['loyaltyPoints'] ?? 0) : 0;
            if ($available < $minPoints) {
                return ['points' => 0, 'discount' => 0.0];
            }

            $maxByOrder = (int) floor(max(0.0, $base) / $rate);
            $points = min($maxPerOrder, $available, $maxByOrder);
            if ($points < 0) {
                $points = 0;
            }

            return ['points' => $points, 'discount' => round($points * $rate, 2)];
        }

        private function generateOrderId(): string
        {
            return 'CF_' . strtoupper(bin2hex(random_bytes(6)));
        }

        private function formatPhone(string $phone): string
        {
            $digits = preg_replace('/[^0-9+]/', '', $phone);
            $digits = is_string($digits) ? $digits : '';
            if ($digits === '') {
                return '';
            }
            if ($digits[0] === '+') {
                return $digits;
            }
            if (strlen($digits) === 10) {
                return '+91' . $digits;
            }
            if (strlen($digits) === 12 && str_starts_with($digits, '91')) {
                return '+' . $digits;
            }
            return '+' . $digits;
        }
    }
