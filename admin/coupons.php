<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Coupons';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $action = (string) ($_POST['action'] ?? 'save');
    try {
        if ($action === 'delete') {
            $code = strtoupper(trim((string) ($_POST['code'] ?? '')));
            if ($code !== '') {
                $rtdb->delete('coupons/' . $code);
            }
            brisko_flash('success', 'Coupon removed.');
        } else {
            $code = strtoupper(trim((string) ($_POST['code'] ?? '')));
            if ($code === '') {
                throw new InvalidArgumentException('Code is required.');
            }
            $validFrom = strtotime((string) ($_POST['validFrom'] ?? '')) ?: time();
            $validTo = strtotime((string) ($_POST['validTo'] ?? '')) ?: strtotime('+1 year');
            $rtdb->put('coupons/' . $code, [
                'description' => trim((string) ($_POST['description'] ?? '')),
                'discountType' => ($_POST['discountType'] ?? 'flat') === 'percent' ? 'percent' : 'flat',
                'discountValue' => (float) ($_POST['discountValue'] ?? 0),
                'minOrderValue' => (float) ($_POST['minOrderValue'] ?? 0),
                'maxDiscount' => (float) ($_POST['maxDiscount'] ?? 0),
                'validFrom' => $validFrom * 1000,
                'validTo' => $validTo * 1000,
                'usageLimitPerUser' => (int) ($_POST['usageLimitPerUser'] ?? 1),
                'isFirstOrderOnly' => isset($_POST['isFirstOrderOnly']),
                'isActive' => isset($_POST['isActive']),
            ]);
            brisko_flash('success', 'Coupon saved.');
        }
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('coupons.php');
}

$coupons = brisko_map($rtdb->get('coupons'));
$editCode = strtoupper((string) ($_GET['edit'] ?? ''));
$edit = $editCode !== '' && isset($coupons[$editCode]) ? $coupons[$editCode] : null;
$openFormModal = $edit !== null || isset($_GET['add']);

require __DIR__ . '/includes/header.php';
?>
<div class="page-toolbar">
    <p class="text-muted mb-0"><?= count($coupons) ?> coupons</p>
    <?php if ($edit): ?>
        <a class="btn btn-primary" href="coupons.php?add=1"><i class="bi bi-plus-lg"></i> Add coupon</a>
    <?php else: ?>
        <button class="btn btn-primary" type="button" data-bs-toggle="modal" data-bs-target="#formModal">
            <i class="bi bi-plus-lg"></i> Add coupon
        </button>
    <?php endif; ?>
</div>
<div class="table-card">
    <div class="table-responsive">
    <table class="table">
        <thead><tr><th>Code</th><th>Offer</th><th>Window</th><th></th></tr></thead>
        <tbody>
        <?php if ($coupons === []): ?>
            <tr><td colspan="4" class="empty-note">No coupons yet. Add one to get started.</td></tr>
        <?php else: foreach ($coupons as $code => $c): ?>
            <tr>
                <td><strong><?= brisko_h((string) $code) ?></strong></td>
                <td><?= brisko_h((string) ($c['description'] ?? '')) ?><div class="small text-muted"><?= brisko_h((string) ($c['discountType'] ?? '')) ?> <?= brisko_h((string) ($c['discountValue'] ?? '')) ?></div></td>
                <td><?= brisko_h(brisko_dt($c['validFrom'] ?? 0)) ?><br><?= brisko_h(brisko_dt($c['validTo'] ?? 0)) ?></td>
                <td class="text-end">
                    <a class="btn btn-sm btn-outline-dark" href="coupons.php?edit=<?= brisko_h((string) $code) ?>">Edit</a>
                    <form method="post" class="d-inline" onsubmit="return confirm('Delete coupon?')">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="code" value="<?= brisko_h((string) $code) ?>">
                        <button class="btn btn-sm btn-outline-danger" type="submit">Delete</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; endif; ?>
        </tbody>
    </table>
    </div>
</div>
<div class="modal fade" id="formModal" tabindex="-1" aria-labelledby="formModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable modal-fullscreen-sm-down">
        <form class="modal-content" method="post">
                <div class="modal-header">
                    <h2 class="modal-title h5" id="formModalLabel"><?= $edit ? 'Edit coupon' : 'Add coupon' ?></h2>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                    <div class="mb-3"><label class="form-label" for="cCode">Code</label><input class="form-control" id="cCode" name="code" required value="<?= brisko_h($editCode) ?>" <?= $edit ? 'readonly' : '' ?>></div>
                    <div class="mb-3"><label class="form-label" for="cDesc">Description</label><input class="form-control" id="cDesc" name="description" value="<?= brisko_h((string) ($edit['description'] ?? '')) ?>"></div>
                    <div class="mb-3">
                        <label class="form-label" for="cType">Type</label>
                        <select class="form-select" id="cType" name="discountType">
                            <option value="flat" <?= (($edit['discountType'] ?? '') === 'flat') ? 'selected' : '' ?>>Flat</option>
                            <option value="percent" <?= (($edit['discountType'] ?? '') === 'percent') ? 'selected' : '' ?>>Percent</option>
                        </select>
                    </div>
                    <div class="mb-3"><label class="form-label" for="cVal">Value</label><input class="form-control" id="cVal" type="number" step="0.01" name="discountValue" value="<?= brisko_h((string) ($edit['discountValue'] ?? '')) ?>"></div>
                    <div class="mb-3"><label class="form-label" for="cMin">Min order</label><input class="form-control" id="cMin" type="number" step="0.01" name="minOrderValue" value="<?= brisko_h((string) ($edit['minOrderValue'] ?? '')) ?>"></div>
                    <div class="mb-3"><label class="form-label" for="cMax">Max discount</label><input class="form-control" id="cMax" type="number" step="0.01" name="maxDiscount" value="<?= brisko_h((string) ($edit['maxDiscount'] ?? '')) ?>"></div>
                    <div class="mb-3"><label class="form-label" for="cFrom">Valid from</label><input class="form-control" id="cFrom" type="date" name="validFrom" value="<?= !empty($edit['validFrom']) ? date('Y-m-d', (int) ($edit['validFrom'] / 1000)) : date('Y-m-d') ?>"></div>
                    <div class="mb-3"><label class="form-label" for="cTo">Valid to</label><input class="form-control" id="cTo" type="date" name="validTo" value="<?= !empty($edit['validTo']) ? date('Y-m-d', (int) ($edit['validTo'] / 1000)) : date('Y-m-d', strtotime('+1 year')) ?>"></div>
                    <div class="mb-3"><label class="form-label" for="cLimit">Usage limit / user</label><input class="form-control" id="cLimit" type="number" name="usageLimitPerUser" value="<?= (int) ($edit['usageLimitPerUser'] ?? 1) ?>"></div>
                    <div class="form-check mb-2"><input class="form-check-input" type="checkbox" name="isFirstOrderOnly" id="fo" <?= !empty($edit['isFirstOrderOnly']) ? 'checked' : '' ?>><label class="form-check-label" for="fo">First order only</label></div>
                    <div class="form-check"><input class="form-check-input" type="checkbox" name="isActive" id="ia" <?= ($edit['isActive'] ?? true) ? 'checked' : '' ?>><label class="form-check-label" for="ia">Active</label></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-primary" type="submit">Save coupon</button>
                </div>
        </form>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
