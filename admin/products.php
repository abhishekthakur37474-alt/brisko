<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Products';
$rtdb = brisko_rtdb();

function brisko_parse_option_fields(string $key): array
{
    $ids = (array) ($_POST[$key . '_id'] ?? []);
    $names = (array) ($_POST[$key . '_name'] ?? []);
    $prices = (array) ($_POST[$key . '_price'] ?? []);
    $out = [];
    $n = max(count($ids), count($names), count($prices));
    for ($i = 0; $i < $n; $i++) {
        $id = trim((string) ($ids[$i] ?? ''));
        $name = trim((string) ($names[$i] ?? ''));
        if ($id === '' && $name === '') {
            continue;
        }
        $id = brisko_slug($id !== '' ? $id : $name);
        $out[$id] = [
            'name' => $name !== '' ? $name : $id,
            'price' => (float) ($prices[$i] ?? 0),
        ];
    }
    return $out;
}

function brisko_option_list($node): array
{
    if (!is_array($node) || $node === []) {
        return [['id' => '', 'name' => '', 'price' => '']];
    }
    $rows = [];
    foreach ($node as $id => $row) {
        if (!is_array($row)) {
            continue;
        }
        $rows[] = [
            'id' => (string) $id,
            'name' => (string) ($row['name'] ?? $id),
            'price' => (string) ($row['price'] ?? 0),
        ];
    }
    return $rows === [] ? [['id' => '', 'name' => '', 'price' => '']] : $rows;
}

function brisko_render_option_editor(string $key, string $label, array $rows): void
{
    ?>
    <div class="col-12">
        <div class="option-editor">
            <div class="d-flex justify-content-between align-items-center mb-2">
                <span class="form-label mb-0"><?= brisko_h($label) ?></span>
                <button class="btn btn-sm btn-outline-dark option-add" type="button" data-option="<?= brisko_h($key) ?>">
                    <i class="bi bi-plus-lg"></i> Add
                </button>
            </div>
            <div class="option-head row g-2 d-none d-md-flex">
                <div class="col-md-4"><span class="small text-muted">ID</span></div>
                <div class="col-md-4"><span class="small text-muted">Name</span></div>
                <div class="col-md-3"><span class="small text-muted">Price</span></div>
            </div>
            <div class="option-rows" id="<?= brisko_h($key) ?>Rows">
                <?php foreach ($rows as $row): ?>
                    <div class="option-row row g-2 align-items-end">
                        <div class="col-md-4">
                            <label class="form-label small d-md-none">ID</label>
                            <input class="form-control" name="<?= brisko_h($key) ?>_id[]" placeholder="regular" value="<?= brisko_h((string) ($row['id'] ?? '')) ?>">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label small d-md-none">Name</label>
                            <input class="form-control" name="<?= brisko_h($key) ?>_name[]" placeholder="Regular" value="<?= brisko_h((string) ($row['name'] ?? '')) ?>">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label small d-md-none">Price</label>
                            <input class="form-control" type="number" step="0.01" name="<?= brisko_h($key) ?>_price[]" placeholder="0" value="<?= brisko_h((string) ($row['price'] ?? '')) ?>">
                        </div>
                        <div class="col-md-1">
                            <button class="btn btn-outline-danger option-remove w-100" type="button" aria-label="Remove">
                                <i class="bi bi-x-lg"></i>
                            </button>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
    <?php
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $action = (string) ($_POST['action'] ?? 'save');
    try {
        if ($action === 'delete') {
            $id = (string) ($_POST['id'] ?? '');
            if ($id !== '') {
                $rtdb->delete('products/' . $id);
            }
            brisko_flash('success', 'Product removed.');
        } else {
            $id = trim((string) ($_POST['id'] ?? ''));
            $name = trim((string) ($_POST['name'] ?? ''));
            if ($name === '') {
                throw new InvalidArgumentException('Name is required.');
            }
            if ($id === '') {
                $id = brisko_slug($name);
            }
            $images = [];
            $existing = brisko_imgbb_from_request('imageFile', (string) ($_POST['image0'] ?? ''));
            if ($existing !== '') {
                $images['0'] = $existing;
            }
            $image1 = brisko_imgbb_from_request('imageFile1', (string) ($_POST['image1'] ?? ''));
            if ($image1 !== '') {
                $images['1'] = $image1;
            }
            $outletIds = [];
            foreach ((array) ($_POST['outletIds'] ?? []) as $oid) {
                $outletIds[(string) $oid] = true;
            }
            $custom = [
                'sizes' => brisko_parse_option_fields('sizes'),
                'crusts' => brisko_parse_option_fields('crusts'),
                'toppings' => brisko_parse_option_fields('toppings'),
                'addons' => brisko_parse_option_fields('addons'),
            ];
            $existingProduct = $rtdb->get('products/' . $id);
            $avg = is_array($existingProduct) ? (float) ($existingProduct['avgRating'] ?? 0) : 0;
            $count = is_array($existingProduct) ? (int) ($existingProduct['reviewCount'] ?? 0) : 0;
            $rtdb->put('products/' . $id, [
                'name' => $name,
                'description' => trim((string) ($_POST['description'] ?? '')),
                'categoryId' => trim((string) ($_POST['categoryId'] ?? '')),
                'images' => $images === [] ? new stdClass() : $images,
                'basePrice' => (float) ($_POST['basePrice'] ?? 0),
                'isVeg' => isset($_POST['isVeg']),
                'isBestSeller' => isset($_POST['isBestSeller']),
                'isFeatured' => isset($_POST['isFeatured']),
                'isActive' => isset($_POST['isActive']),
                'outletIds' => $outletIds === [] ? new stdClass() : $outletIds,
                'customizations' => $custom,
                'avgRating' => $avg,
                'reviewCount' => $count,
            ]);
            brisko_flash('success', 'Product saved.');
        }
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('products.php');
}

$products = brisko_map($rtdb->get('products'));
$categories = brisko_map($rtdb->get('categories'));
$outlets = brisko_map($rtdb->get('outlets'));
$editId = (string) ($_GET['edit'] ?? '');
$edit = $editId !== '' && isset($products[$editId]) ? $products[$editId] : null;
$editImages = is_array($edit['images'] ?? null) ? $edit['images'] : [];
$editOutlets = is_array($edit['outletIds'] ?? null) ? array_keys($edit['outletIds']) : [];
$custom = is_array($edit['customizations'] ?? null) ? $edit['customizations'] : [];
$sizeRows = brisko_option_list($custom['sizes'] ?? []);
$crustRows = brisko_option_list($custom['crusts'] ?? []);
$toppingRows = brisko_option_list($custom['toppings'] ?? []);
$addonRows = brisko_option_list($custom['addons'] ?? []);
$openFormModal = $edit !== null || isset($_GET['add']);

require __DIR__ . '/includes/header.php';
?>
<div class="page-toolbar">
    <p class="text-muted mb-0"><?= count($products) ?> products</p>
    <?php if ($edit): ?>
        <a class="btn btn-primary" href="products.php?add=1"><i class="bi bi-plus-lg"></i> Add product</a>
    <?php else: ?>
        <button class="btn btn-primary" type="button" data-bs-toggle="modal" data-bs-target="#formModal">
            <i class="bi bi-plus-lg"></i> Add product
        </button>
    <?php endif; ?>
</div>
<div class="table-card">
    <div class="table-responsive">
    <table class="table">
        <thead><tr><th></th><th>Product</th><th>Price</th><th>Flags</th><th></th></tr></thead>
        <tbody>
        <?php if ($products === []): ?>
            <tr><td colspan="5" class="empty-note">No products yet. Add one to get started.</td></tr>
        <?php else: foreach ($products as $id => $p):
            $img = '';
            if (is_array($p['images'] ?? null)) {
                $img = (string) ($p['images']['0'] ?? $p['images'][0] ?? '');
            }
            ?>
            <tr>
                <td><?php if ($img): ?><img class="thumb" src="<?= brisko_h($img) ?>" alt=""><?php endif; ?></td>
                <td>
                    <strong><?= brisko_h((string) ($p['name'] ?? $id)) ?></strong>
                    <div class="small text-muted"><?= brisko_h((string) ($p['categoryId'] ?? '')) ?> · <?= brisko_h((string) $id) ?></div>
                </td>
                <td><?= brisko_h(brisko_money($p['basePrice'] ?? 0)) ?></td>
                <td>
                    <?= !empty($p['isVeg']) || ($p['isVeg'] ?? true) ? 'Veg' : 'Non-veg' ?>
                    <?= !empty($p['isBestSeller']) ? ' · Best' : '' ?>
                    <?= !empty($p['isFeatured']) ? ' · Featured' : '' ?>
                    <?= (($p['isActive'] ?? true) ? '' : ' · Hidden') ?>
                </td>
                <td class="text-end">
                    <a class="btn btn-sm btn-outline-dark" href="products.php?edit=<?= brisko_h((string) $id) ?>">Edit</a>
                    <form method="post" class="d-inline" onsubmit="return confirm('Delete product?')">
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
    <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable modal-fullscreen-sm-down">
        <form class="modal-content" method="post" enctype="multipart/form-data">
                <div class="modal-header">
                    <h2 class="modal-title h5" id="formModalLabel"><?= $edit ? 'Edit product' : 'Add product' ?></h2>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                    <div class="row g-3">
                        <div class="col-md-6"><label class="form-label" for="pId">ID</label><input class="form-control" id="pId" name="id" value="<?= brisko_h($editId) ?>" <?= $edit ? 'readonly' : '' ?>></div>
                        <div class="col-md-6"><label class="form-label" for="pName">Name</label><input class="form-control" id="pName" name="name" required value="<?= brisko_h((string) ($edit['name'] ?? '')) ?>"></div>
                        <div class="col-12"><label class="form-label" for="pDesc">Description</label><textarea class="form-control" id="pDesc" name="description" rows="3"><?= brisko_h((string) ($edit['description'] ?? '')) ?></textarea></div>
                        <div class="col-md-6">
                            <label class="form-label" for="pCat">Category</label>
                            <select class="form-select" id="pCat" name="categoryId">
                                <?php foreach ($categories as $cid => $c): ?>
                                    <option value="<?= brisko_h((string) $cid) ?>" <?= (($edit['categoryId'] ?? '') === $cid) ? 'selected' : '' ?>><?= brisko_h((string) ($c['name'] ?? $cid)) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="col-md-6"><label class="form-label" for="pPrice">Base price</label><input class="form-control" id="pPrice" type="number" step="0.01" name="basePrice" required value="<?= brisko_h((string) ($edit['basePrice'] ?? '')) ?>"></div>
                        <?php
                        $img0 = (string) ($editImages['0'] ?? $editImages[0] ?? '');
                        $img1 = (string) ($editImages['1'] ?? $editImages[1] ?? '');
                        ?>
                        <div class="col-md-6">
                            <label class="form-label" for="pFile">Main image</label>
                            <input class="form-control" id="pFile" type="file" name="imageFile" accept="image/*">
                            <input type="hidden" name="image0" value="<?= brisko_h($img0) ?>">
                            <?php if ($img0 !== ''): ?>
                                <div class="upload-preview"><img src="<?= brisko_h($img0) ?>" alt=""></div>
                            <?php endif; ?>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label" for="pFile1">Second image</label>
                            <input class="form-control" id="pFile1" type="file" name="imageFile1" accept="image/*">
                            <input type="hidden" name="image1" value="<?= brisko_h($img1) ?>">
                            <?php if ($img1 !== ''): ?>
                                <div class="upload-preview"><img src="<?= brisko_h($img1) ?>" alt=""></div>
                            <?php endif; ?>
                        </div>
                        <div class="col-12">
                            <span class="form-label d-block">Outlets</span>
                            <?php foreach ($outlets as $oid => $o): ?>
                                <div class="form-check form-check-inline">
                                    <input class="form-check-input" type="checkbox" name="outletIds[]" value="<?= brisko_h((string) $oid) ?>" id="o<?= brisko_h((string) $oid) ?>" <?= in_array((string) $oid, $editOutlets, true) || $edit === null ? 'checked' : '' ?>>
                                    <label class="form-check-label" for="o<?= brisko_h((string) $oid) ?>"><?= brisko_h((string) ($o['name'] ?? $oid)) ?></label>
                                </div>
                            <?php endforeach; ?>
                        </div>
                        <div class="col-12">
                            <div class="form-check form-check-inline"><input class="form-check-input" type="checkbox" name="isVeg" id="veg" <?= ($edit['isVeg'] ?? true) ? 'checked' : '' ?>><label class="form-check-label" for="veg">Veg</label></div>
                            <div class="form-check form-check-inline"><input class="form-check-input" type="checkbox" name="isBestSeller" id="bs" <?= !empty($edit['isBestSeller']) ? 'checked' : '' ?>><label class="form-check-label" for="bs">Best seller</label></div>
                            <div class="form-check form-check-inline"><input class="form-check-input" type="checkbox" name="isFeatured" id="ft" <?= !empty($edit['isFeatured']) ? 'checked' : '' ?>><label class="form-check-label" for="ft">Featured</label></div>
                            <div class="form-check form-check-inline"><input class="form-check-input" type="checkbox" name="isActive" id="ia" <?= ($edit['isActive'] ?? true) ? 'checked' : '' ?>><label class="form-check-label" for="ia">Active</label></div>
                        </div>
                        <?php
                        brisko_render_option_editor('sizes', 'Sizes', $sizeRows);
                        brisko_render_option_editor('crusts', 'Crusts', $crustRows);
                        brisko_render_option_editor('toppings', 'Toppings', $toppingRows);
                        brisko_render_option_editor('addons', 'Addons', $addonRows);
                        ?>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-primary" type="submit">Save product</button>
                </div>
        </form>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
