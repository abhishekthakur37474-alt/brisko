(function () {
  var toggle = document.getElementById('sidebarToggle');
  var sidebar = document.getElementById('briskoSidebar');
  var backdrop = document.getElementById('sidebarBackdrop');
  if (toggle && sidebar) {
    function close() {
      sidebar.classList.remove('open');
      if (backdrop) backdrop.classList.remove('show');
    }
    toggle.addEventListener('click', function () {
      sidebar.classList.toggle('open');
      if (backdrop) backdrop.classList.toggle('show');
    });
    if (backdrop) backdrop.addEventListener('click', close);
  }

  function optionRowHtml(key) {
    return (
      '<div class="option-row row g-2 align-items-end">' +
        '<div class="col-md-4">' +
          '<label class="form-label small d-md-none">ID</label>' +
          '<input class="form-control" name="' + key + '_id[]" placeholder="regular">' +
        '</div>' +
        '<div class="col-md-4">' +
          '<label class="form-label small d-md-none">Name</label>' +
          '<input class="form-control" name="' + key + '_name[]" placeholder="Regular">' +
        '</div>' +
        '<div class="col-md-3">' +
          '<label class="form-label small d-md-none">Price</label>' +
          '<input class="form-control" type="number" step="0.01" name="' + key + '_price[]" placeholder="0">' +
        '</div>' +
        '<div class="col-md-1">' +
          '<button class="btn btn-outline-danger option-remove w-100" type="button" aria-label="Remove">' +
            '<i class="bi bi-x-lg"></i>' +
          '</button>' +
        '</div>' +
      '</div>'
    );
  }

  document.querySelectorAll('[data-time-preview]').forEach(function (wrap) {
    var target = document.getElementById(wrap.getAttribute('data-time-preview'));
    var hour = wrap.querySelector('[data-role="hour"]');
    var minute = wrap.querySelector('[data-role="minute"]');
    var period = wrap.querySelector('[data-role="period"]');
    if (!target || !hour || !minute || !period) return;
    function update() {
      var m = parseInt(minute.value, 10);
      var mm = isNaN(m) ? '00' : (m < 10 ? '0' + m : String(m));
      target.textContent = hour.value + ':' + mm + ' ' + period.value;
    }
    wrap.addEventListener('change', update);
    update();
  });

  document.querySelectorAll('[data-schedule-toggle]').forEach(function (toggle) {
    var fields = document.getElementById('scheduleFields');
    if (!fields) return;
    function sync() {
      var off = toggle.checked;
      fields.style.opacity = off ? '0.5' : '';
      fields.querySelectorAll('select, input').forEach(function (field) {
        field.disabled = off;
      });
    }
    toggle.addEventListener('change', sync);
    sync();
  });

  document.addEventListener('click', function (e) {
    var addBtn = e.target.closest('.option-add');
    if (addBtn) {
      var key = addBtn.getAttribute('data-option') || '';
      var wrap = document.getElementById(key + 'Rows');
      if (wrap) {
        wrap.insertAdjacentHTML('beforeend', optionRowHtml(key));
      }
      return;
    }
    var removeBtn = e.target.closest('.option-remove');
    if (removeBtn) {
      var row = removeBtn.closest('.option-row');
      var parent = row && row.parentElement;
      if (!row || !parent) return;
      if (parent.querySelectorAll('.option-row').length === 1) {
        row.querySelectorAll('input').forEach(function (input) {
          input.value = '';
        });
        return;
      }
      row.remove();
    }
  });
})();
