<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Outlets';
$rtdb = brisko_rtdb();

function brisko_time_parts(string $value, int $fallbackHour = 12, int $fallbackMinute = 0): array
{
    $raw = strtoupper(trim($value));
    $period = str_contains($raw, 'PM') ? 'PM' : (str_contains($raw, 'AM') ? 'AM' : null);
    $cleaned = preg_replace('/[^0-9:]/', '', $raw) ?? '';
    $segments = array_values(array_filter(explode(':', $cleaned), static fn (string $p): bool => $p !== ''));
    $hour = isset($segments[0]) ? (int) $segments[0] : $fallbackHour;
    $minute = isset($segments[1]) ? (int) $segments[1] : $fallbackMinute;
    if ($hour < 0 || $hour > 23 || $minute < 0 || $minute > 59) {
        $hour = $fallbackHour;
        $minute = $fallbackMinute;
    }
    $period ??= $hour >= 12 ? 'PM' : 'AM';
    $hour %= 12;
    if ($hour === 0) {
        $hour = 12;
    }
    return ['hour' => $hour, 'minute' => $minute, 'period' => $period];
}

function brisko_format_time_12h(string $value): string
{
    $value = trim($value);
    if (preg_replace('/[^0-9]/', '', $value) === '') {
        return $value;
    }
    $parts = brisko_time_parts($value);
    return sprintf('%d:%02d %s', $parts['hour'], $parts['minute'], $parts['period']);
}

function brisko_time_from_request(string $prefix, string $fallback): string
{
    $hour = (int) ($_POST[$prefix . 'Hour'] ?? 0);
    $minute = (int) ($_POST[$prefix . 'Minute'] ?? 0);
    $period = strtoupper((string) ($_POST[$prefix . 'Period'] ?? ''));
    if ($hour >= 1 && $hour <= 12 && $minute >= 0 && $minute <= 59 && in_array($period, ['AM', 'PM'], true)) {
        return sprintf('%d:%02d %s', $hour, $minute, $period);
    }
    $single = trim((string) ($_POST[$prefix . 'Time'] ?? ''));
    return $single !== '' ? $single : $fallback;
}

function brisko_time_select(string $name, array $parts): string
{
    $html = '<div class="row g-2" data-time-preview="' . brisko_h($name . 'Preview') . '">';
    $html .= '<div class="col-4"><select class="form-select" name="' . brisko_h($name . 'Hour') . '" data-role="hour" aria-label="Hour">';
    for ($hour = 1; $hour <= 12; $hour++) {
        $html .= '<option value="' . $hour . '"' . ((int) $parts['hour'] === $hour ? ' selected' : '') . '>' . $hour . '</option>';
    }
    $html .= '</select></div>';
    $html .= '<div class="col-4"><select class="form-select" name="' . brisko_h($name . 'Minute') . '" data-role="minute" aria-label="Minute">';
    for ($minute = 0; $minute <= 59; $minute++) {
        $html .= '<option value="' . $minute . '"' . ((int) $parts['minute'] === $minute ? ' selected' : '') . '>' . str_pad((string) $minute, 2, '0', STR_PAD_LEFT) . '</option>';
    }
    $html .= '</select></div>';
    $html .= '<div class="col-4"><select class="form-select" name="' . brisko_h($name . 'Period') . '" data-role="period" aria-label="AM or PM">';
    foreach (['AM', 'PM'] as $period) {
        $html .= '<option value="' . $period . '"' . ((string) $parts['period'] === $period ? ' selected' : '') . '>' . $period . '</option>';
    }
    $html .= '</select></div>';
    $html .= '</div>';
    return $html;
}

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
                'openTime' => brisko_time_from_request('open', '11:00 AM'),
                'closeTime' => brisko_time_from_request('close', '11:00 PM'),
                'googleMapsUrl' => trim((string) ($_POST['googleMapsUrl'] ?? '')),
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
$openParts = brisko_time_parts((string) ($edit['openTime'] ?? ''), 11, 0);
$closeParts = brisko_time_parts((string) ($edit['closeTime'] ?? ''), 23, 0);

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
                    <?php if (trim((string) ($o['googleMapsUrl'] ?? '')) !== ''): ?>
                        <a class="small" href="<?= brisko_h((string) $o['googleMapsUrl']) ?>" target="_blank" rel="noopener">View on Google Maps</a>
                    <?php endif; ?>
                </td>
                <td><?= brisko_h((string) ($o['serviceRadiusKm'] ?? '')) ?> km</td>
                <td><?= brisko_h(brisko_format_time_12h((string) ($o['openTime'] ?? ''))) ?> – <?= brisko_h(brisko_format_time_12h((string) ($o['closeTime'] ?? ''))) ?></td>
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
                    <div class="mb-3">
                        <label class="form-label" for="outMapUrl">Google Maps URL</label>
                        <input class="form-control" id="outMapUrl" name="googleMapsUrl" type="url" placeholder="https://maps.app.goo.gl/..." value="<?= brisko_h((string) ($edit['googleMapsUrl'] ?? '')) ?>">
                        <div class="form-text">Shown to customers on Takeaway &amp; Dine-In order details.</div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Opening time</label>
                        <?= brisko_time_select('open', $openParts) ?>
                        <div class="form-text">Opens at <span id="openPreview"><?= brisko_h(brisko_format_time_12h((string) ($edit['openTime'] ?? '11:00 AM'))) ?></span></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Closing time</label>
                        <?= brisko_time_select('close', $closeParts) ?>
                        <div class="form-text">Closes at <span id="closePreview"><?= brisko_h(brisko_format_time_12h((string) ($edit['closeTime'] ?? '11:00 PM'))) ?></span></div>
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
