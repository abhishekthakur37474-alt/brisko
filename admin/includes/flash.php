<?php

declare(strict_types=1);

$flash = brisko_flash();
if ($flash):
    $cls = ($flash['type'] ?? '') === 'success' ? 'alert-success' : 'alert-danger';
    ?>
    <div class="alert <?= $cls ?> alert-dismissible fade show" role="alert">
        <?= brisko_h((string) $flash['message']) ?>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
<?php endif;