<?php

declare(strict_types=1);

require_once __DIR__ . '/includes/require_admin.php';

$pageTitle = 'Categories';
$rtdb = brisko_rtdb();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    brisko_csrf_check();
    $action = (string) ($_POST['action'] ?? 'save');
    try {
        if ($action === 'delete') {
            $id = (string) ($_POST['id'] ?? '');
            if ($id !== '') {
                $rtdb->delete('categories/' . $id);
            }
            brisko_flash('success', 'Category removed.');
        } else {
            $id = trim((string) ($_POST['id'] ?? ''));
            $name = trim((string) ($_POST['name'] ?? ''));
            if ($name === '') {
                throw new InvalidArgumentException('Name is required.');
            }
            if ($id === '') {
                $id = brisko_slug($name);
            }
            $rtdb->put('categories/' . $id, [
                'name' => $name,
                'imageUrl' => brisko_imgbb_from_request('imageFile', (string) ($_POST['imageUrl'] ?? '')),
                'sortOrder' => (int) ($_POST['sortOrder'] ?? 0),
                'isActive' => isset($_POST['isActive']),
            ]);
            brisko_flash('success', 'Category saved.');
        }
    } catch (Throwable $e) {
        brisko_flash('error', $e->getMessage());
    }
    brisko_redirect('categories.php');
}

$categories = brisko_map($rtdb->get('categories'));
uasort($categories, static fn ($a, $b) => ((int) ($a['sortOrder'] ?? 0)) <=> ((int) ($b['sortOrder'] ?? 0)));
$editId = (string) ($_GET['edit'] ?? '');
$edit = $editId !== '' && isset($categories[$editId]) ? $categories[$editId] : null;
$openFormModal = $edit !== null || isset($_GET['add']);

require __DIR__ . '/includes/header.php';
?>
<div class="page-toolbar">
    <p class="text-muted mb-0"><?= count($categories) ?> categories</p>
    <?php if ($edit): ?>
        <a class="btn btn-primary" href="categories.php?add=1"><i class="bi bi-plus-lg"></i> Add category</a>
    <?php else: ?>
        <button class="btn btn-primary" type="button" data-bs-toggle="modal" data-bs-target="#formModal">
            <i class="bi bi-plus-lg"></i> Add category
        </button>
    <?php endif; ?>
</div>
<div class="table-card">
    <div class="table-responsive">
    <table class="table">
        <thead><tr><th></th><th>Name</th><th>Order</th><th>Status</th><th></th></tr></thead>
        <tbody>
        <?php if ($categories === []): ?>
            <tr><td colspan="5" class="empty-note">No categories yet. Add one to get started.</td></tr>
        <?php else: foreach ($categories as $id => $c): ?>
            <tr>
                <td><?php if (!empty($c['imageUrl'])): ?><img class="thumb" src="<?= brisko_h((string) $c['imageUrl']) ?>" alt=""><?php endif; ?></td>
                <td><strong><?= brisko_h((string) ($c['name'] ?? $id)) ?></strong><div class="text-muted small"><?= brisko_h((string) $id) ?></div></td>
                <td><?= (int) ($c['sortOrder'] ?? 0) ?></td>
                <td><?= !empty($c['isActive']) || ($c['isActive'] ?? true) ? 'Active' : 'Hidden' ?></td>
                <td class="text-end">
                    <a class="btn btn-sm btn-outline-dark" href="categories.php?edit=<?= brisko_h((string) $id) ?>">Edit</a>
                    <form method="post" class="d-inline" onsubmit="return confirm('Delete this category?')">
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
        <form class="modal-content" method="post" enctype="multipart/form-data">
                <div class="modal-header">
                    <h2 class="modal-title h5" id="formModalLabel"><?= $edit ? 'Edit category' : 'Add category' ?></h2>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="_csrf" value="<?= brisko_h(brisko_csrf_token()) ?>">
                    <input type="hidden" name="action" value="save">
                    <div class="mb-3">
                        <label class="form-label" for="catId">ID</label>
                        <input class="form-control" id="catId" name="id" value="<?= brisko_h($editId) ?>" <?= $edit ? 'readonly' : '' ?> placeholder="pizzas">
                    </div>
                    <div class="mb-3">
                        <label class="form-label" for="catName">Name</label>
                        <input class="form-control" id="catName" name="name" required value="<?= brisko_h((string) ($edit['name'] ?? '')) ?>">
                    </div>
                    <div class="mb-3">
                        <label class="form-label" for="catFile">Image</label>
                        <input class="form-control" id="catFile" type="file" name="imageFile" accept="image/*">
                        <input type="hidden" name="imageUrl" value="<?= brisko_h((string) ($edit['imageUrl'] ?? '')) ?>">
                        <?php if (!empty($edit['imageUrl'])): ?>
                            <div class="upload-preview"><img src="<?= brisko_h((string) $edit['imageUrl']) ?>" alt=""></div>
                        <?php endif; ?>
                    </div>
                    <div class="mb-3">
                        <label class="form-label" for="catSort">Sort order</label>
                        <input class="form-control" id="catSort" type="number" name="sortOrder" value="<?= (int) ($edit['sortOrder'] ?? 0) ?>">
                    </div>
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" name="isActive" id="isActive" <?= ($edit['isActive'] ?? true) ? 'checked' : '' ?>>
                        <label class="form-check-label" for="isActive">Active</label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-dark" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-primary" type="submit">Save category</button>
                </div>
        </form>
    </div>
</div>
<?php require __DIR__ . '/includes/footer.php';
