<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Loyalty';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    try {
        $rtdb->put('loyaltyConfig', [
            'pointsPerRupeeSpent' => (float) ($_POST['pointsPerRupeeSpent'] ?? 0.05),
            'redemptionValuePerPoint' => (float) ($_POST['redemptionValuePerPoint'] ?? 1),
            'minPointsToRedeem' => (int) ($_POST['minPointsToRedeem'] ?? 50),
            'maxPointsUsablePerOrder' => (int) ($_POST['maxPointsUsablePerOrder'] ?? 200),
            'pointsExpiryDays' => (int) ($_POST['pointsExpiryDays'] ?? 90),
            'minOrderValueForPoints' => (float) ($_POST['minOrderValueForPoints'] ?? 0),
        ]);
        brisko_flash('success', 'Loyalty config saved.');
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('loyalty_config.php');
}

$cfg = brisko_map($rtdb->get('loyaltyConfig'));
require __DIR__ . '/includes/header.php';
?>
<div class="row">
    <div class="col-lg-6">
        <div class="card p-3">
            <h2 class="h5">Program rules</h2>
            <form method="post">
                <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                <div class="mb-3"><label class="form-label">Points per rupee spent</label><input class="form-control" name="pointsPerRupeeSpent" type="number" step="0.01" value="<?= brisko_h((string) ($cfg['pointsPerRupeeSpent'] ?? 0.05)) ?>"></div>
                <div class="mb-3"><label class="form-label">Redemption value per point</label><input class="form-control" name="redemptionValuePerPoint" type="number" step="0.01" value="<?= brisko_h((string) ($cfg['redemptionValuePerPoint'] ?? 1)) ?>"></div>
                <div class="mb-3"><label class="form-label">Min points to redeem</label><input class="form-control" name="minPointsToRedeem" type="number" value="<?= (int) ($cfg['minPointsToRedeem'] ?? 50) ?>"></div>
                <div class="mb-3"><label class="form-label">Max points per order</label><input class="form-control" name="maxPointsUsablePerOrder" type="number" value="<?= (int) ($cfg['maxPointsUsablePerOrder'] ?? 200) ?>"></div>
                <div class="mb-3"><label class="form-label">Points expiry days</label><input class="form-control" name="pointsExpiryDays" type="number" value="<?= (int) ($cfg['pointsExpiryDays'] ?? 90) ?>"></div>
                <div class="mb-3">
                    <label class="form-label">Minimum order subtotal to earn points</label>
                    <input class="form-control" name="minOrderValueForPoints" type="number" step="0.01" min="0" value="<?= brisko_h((string) ($cfg['minOrderValueForPoints'] ?? 0)) ?>">
                    <div class="form-text">Orders whose subtotal (items only, before GST/delivery/discounts) is below this value earn no loyalty points. Points are also calculated on the subtotal. Set 0 to always earn.</div>
                </div>
                <button class="btn btn-primary" type="submit">Save</button>
            </form>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
