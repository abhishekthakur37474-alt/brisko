<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Outlets';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $action = (string) ($_POST['action'] ?? 'save');
    try {
        if ($action === 'delete') {
            $id = (string) ($_POST['id'] ?? '');
            if ($id !== '') {
                $rtdb->delete('outlets/' . $id);
            }
            brisko_flash('success', 'Outlet removed.');
        } else {
            $id = trim((string) ($_POST['id'] ?? ''));
            $name = trim((string) ($_POST['name'] ?? ''));
            if ($name === '') {
                throw new InvalidArgumentException('Name is required.');
            }
            if ($id === '') {
                $id = brisko_slug($name);
            }
            $rtdb->put('outlets/' . $id, [
                'name' => $name,
                'address' => trim((string) ($_POST['address'] ?? '')),
                'lat' => (float) ($_POST['lat'] ?? 0),
                'lng' => (float) ($_POST['lng'] ?? 0),
                'serviceRadiusKm' => (float) ($_POST['serviceRadiusKm'] ?? 5),
                'isActive' => isset($_POST['isActive']),
                'contactNumber' => trim((string) ($_POST['contactNumber'] ?? '')),
                'openTime' => trim((string) ($_POST['openTime'] ?? '11:00')),
                'closeTime' => trim((string) ($_POST['closeTime'] ?? '23:00')),
            ]);
            brisko_flash('success', 'Outlet saved.');
        }
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('outlets.php');
}

$outlets = brisko_map($rtdb->get('outlets'));
$editId = (string) ($_GET['edit'] ?? '');
$edit = $editId !== '' && isset($outlets[$editId]) ? $outlets[$editId] : null;
$openFormModal = $edit !== null || isset($_GET['add']);

require __DIR__ . '/includes/header.php';
?>
<div class="page-toolbar">
    <p class="text-muted mb-0"><?= count($outlets) ?> outlets</p>
    <?php if ($edit): ?>
        <a class="btn btn-primary" href="outlets.php?add=1"><i class="bi bi-plus-lg"></i> Add outlet</a>
    <?php else: ?>
        <button class="btn btn-primary" type="button" data-bs-toggle="modal" data-bs-target="#formModal">
            <i class="bi bi-plus-lg"></i> Add outlet
        </button>
    <?php endif; ?>
</div>
<div class="table-card">
    <div class="table-responsive">
    <table class="table">
        <thead><tr><th>Outlet</th><th>Radius</th><th>Hours</th><th></th></tr></thead>
        <tbody>
        <?php if ($outlets === []): ?>
            <tr><td colspan="4" class="empty-note">No outlets yet. Add one to get started.</td></tr>
        <?php else: foreach ($outlets as $id => $o): ?>
            <tr>
                <td>
                    <strong><?= brisko_h((string) ($o['name'] ?? $id)) ?></strong>
                    <div class="text-muted small"><?= brisko_h((string) ($o['address'] ?? '')) ?></div>
                </td>
                <td><?= brisko_h((string) ($o['serviceRadiusKm'] ?? '')) ?> km</td>
                <td><?= brisko_h((string) ($o['openTime'] ?? '')) ?> – <?= brisko_h((string) ($o['closeTime'] ?? '')) ?></td>
                <td class="text-end">
                    <a class="btn btn-sm btn-outline-dark" href="outlets.php?edit=<?= brisko_h((string) $id) ?>">Edit</a>
                    <form method="post" class="d-inline" onsubmit="return confirm('Delete this outlet?')">
                        <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<?= brisko_h((string) $id) ?>">
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
                    <h2 class="modal-title h5" id="formModalLabel"><?= $edit ? 'Edit outlet' : 'Add outlet' ?></h2>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                    <div class="mb-3"><label class="form-label" for="outId">ID</label><input class="form-control" id="outId" name="id" value="<?= brisko_h($editId) ?>" <?= $edit ? 'readonly' : '' ?>></div>
                    <div class="mb-3"><label class="form-label" for="outName">Name</label><input class="form-control" id="outName" name="name" required value="<?= brisko_h((string) ($edit['name'] ?? '')) ?>"></div>
                    <div class="mb-3"><label class="form-label" for="outAddr">Address</label><textarea class="form-control" id="outAddr" name="address" rows="2"><?= brisko_h((string) ($edit['address'] ?? '')) ?></textarea></div>
                    <div class="row g-2">
                        <div class="col-6 mb-3"><label class="form-label" for="outLat">Lat</label><input class="form-control" id="outLat" name="lat" value="<?= brisko_h((string) ($edit['lat'] ?? '')) ?>"></div>
                        <div class="col-6 mb-3"><label class="form-label" for="outLng">Lng</label><input class="form-control" id="outLng" name="lng" value="<?= brisko_h((string) ($edit['lng'] ?? '')) ?>"></div>
                    </div>
                    <div class="mb-3"><label class="form-label" for="outRadius">Service radius (km)</label><input class="form-control" id="outRadius" name="serviceRadiusKm" type="number" step="0.1" value="<?= brisko_h((string) ($edit['serviceRadiusKm'] ?? '25')) ?>"></div>
                    <div class="mb-3"><label class="form-label" for="outPhone">Contact</label><input class="form-control" id="outPhone" name="contactNumber" value="<?= brisko_h((string) ($edit['contactNumber'] ?? '')) ?>"></div>
                    <div class="row g-2">
                        <div class="col-6 mb-3"><label class="form-label" for="outOpen">Open</label><input class="form-control" id="outOpen" name="openTime" value="<?= brisko_h((string) ($edit['openTime'] ?? '11:00')) ?>"></div>
                        <div class="col-6 mb-3"><label class="form-label" for="outClose">Close</label><input class="form-control" id="outClose" name="closeTime" value="<?= brisko_h((string) ($edit['closeTime'] ?? '23:00')) ?>"></div>
                    </div>
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" name="isActive" id="isActive" <?= ($edit['isActive'] ?? true) ? 'checked' : '' ?>>
                        <label class="form-check-label" for="isActive">Active</label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-primary" type="submit">Save outlet</button>
                </div>
        </form>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
