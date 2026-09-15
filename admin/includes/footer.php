<?php

declare(strict_types=1);
?>
    </main>
</div>
</div>
<div class="sidebar-backdrop" id="sidebarBackdrop"></div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="assets/js/admin.js"></script>
<?php if (!empty($openFormModal)): ?>
<script>
document.addEventListener('DOMContentLoaded', function () {
  var el = document.getElementById('formModal');
  if (el && window.bootstrap) {
    window.bootstrap.Modal.getOrCreateInstance(el).show();
  }
});
</script>
<?php endif; ?>
</body>
</html>
