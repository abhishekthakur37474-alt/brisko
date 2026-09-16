<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Payment Settings';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    try {
        $existing = brisko_map($rtdb->get('settings/payment'));
        $qrImageUrl = brisko_imgbb_from_request('qrFile', (string) ($_POST['qrImageUrl'] ?? ($existing['qrImageUrl'] ?? '')));
        $upiId = trim((string) ($_POST['upiId'] ?? ''));
        $payeeName = trim((string) ($_POST['payeeName'] ?? ''));
        $instructions = trim((string) ($_POST['instructions'] ?? ''));
        $waitMinutes = max(1, (int) ($_POST['waitMinutes'] ?? 5));

        $rtdb->put('settings/payment', [
            'qrImageUrl' => $qrImageUrl,
            'upiId' => $upiId,
            'payeeName' => $payeeName,
            'instructions' => $instructions,
            'waitMinutes' => $waitMinutes,
            'updatedAt' => brisko_now_ms(),
        ]);
        brisko_flash('success', 'Payment settings saved.');
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('payment_settings.php');
}

$cfg = brisko_map($rtdb->get('settings/payment'));
require __DIR__ . '/includes/header.php';
?>
<div class="row g-3">
    <div class="col-lg-7">
        <div class="card p-3">
            <h2 class="h5">Online payment (UPI / QR)</h2>
            <p class="text-muted small mb-3">
                Shown to customers who choose <strong>Online Payment</strong> at checkout. They scan the QR
                or pay to the UPI ID, then upload a payment screenshot and the transaction id. The order stays
                waiting until an admin confirms the payment from the Orders page.
            </p>
            <form method="post" enctype="multipart/form-data">
                <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                <div class="mb-3">
                    <label class="form-label">UPI ID (VPA)</label>
                    <input class="form-control" name="upiId" value="<?= brisko_h((string) ($cfg['upiId'] ?? '')) ?>" placeholder="brisko@ybl">
                    <div class="form-text">The payee address customers copy on the payment screen.</div>
                </div>
                <div class="mb-3">
                    <label class="form-label">Payee name</label>
                    <input class="form-control" name="payeeName" value="<?= brisko_h((string) ($cfg['payeeName'] ?? '')) ?>" placeholder="Brisko Pizza">
                </div>
                <div class="mb-3">
                    <label class="form-label">Payment QR code</label>
                    <input class="form-control" type="file" name="qrFile" accept="image/*">
                    <input type="hidden" name="qrImageUrl" value="<?= brisko_h((string) ($cfg['qrImageUrl'] ?? '')) ?>">
                    <div class="form-text">Upload the UPI QR image customers should scan. Leave empty to keep the current one.</div>
                </div>
                <div class="mb-3">
                    <label class="form-label">Instructions (optional)</label>
                    <textarea class="form-control" name="instructions" rows="3" placeholder="Pay the exact amount and upload the screenshot."><?= brisko_h((string) ($cfg['instructions'] ?? '')) ?></textarea>
                </div>
                <div class="mb-3">
                    <label class="form-label">Confirmation wait time (minutes)</label>
                    <input class="form-control" type="number" min="1" name="waitMinutes" value="<?= (int) ($cfg['waitMinutes'] ?? 5) ?>">
                    <div class="form-text">Message shown to the customer while the payment is being reviewed.</div>
                </div>
                <button class="btn btn-primary" type="submit">Save</button>
            </form>
        </div>
    </div>
    <div class="col-lg-5">
        <div class="card p-3">
            <h2 class="h6">Current QR</h2>
            <?php $qr = trim((string) ($cfg['qrImageUrl'] ?? '')); ?>
            <?php if ($qr !== ''): ?>
                <img src="<?= brisko_h($qr) ?>" alt="Payment QR" class="img-fluid rounded border" style="max-height: 360px; object-fit: contain;">
                <p class="small text-muted mt-2 mb-0">UPI ID: <?= brisko_h((string) ($cfg['upiId'] ?? '-')) ?></p>
            <?php else: ?>
                <p class="text-muted mb-0">No QR uploaded yet.</p>
            <?php endif; ?>
        </div>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
