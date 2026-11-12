import { el } from './dom.js';
import { state, getSelectedTarget } from '../state.js';
import { api } from '../api.js';
import { logToConsole, showAlert } from './logger.js';

export async function runMaintenance(action) {
  const target = getSelectedTarget(el);
  const payload = {
    ...target,
    action,
    level: el.selectCleanLevel.value
  };

  if (action === 'power-clean') {
    const confirmed = confirm(
      state.currentLang === 'id'
        ? 'PERINGATAN: Power Cleaning menggunakan volume tinta yang cukup banyak. Lanjutkan pengisian daya tinta?'
        : 'WARNING: Power Cleaning consumes a significant amount of ink. Proceed with ink charge?'
    );
    if (!confirmed) return;
  }

  logToConsole(`Starting maintenance task: ${action}...`, 'info');
  showAlert(
    state.currentLang === 'id'
      ? `Sedang menjalankan perintah ${action}... Harap tunggu.`
      : `Executing ${action}... Please wait.`,
    'info'
  );

  try {
    const result = await api.runMaintenance(payload);

    if (result.ok) {
      logToConsole(`Maintenance task ${action} completed.`, 'success');
      showAlert(
        state.currentLang === 'id'
          ? `Tindakan ${action} berhasil dieksekusi.`
          : `Action ${action} executed successfully.`,
        'success'
      );
    } else {
      const err = result.error || result.error_code || 'Gagal menjalankan pemeliharaan.';
      logToConsole(`Maintenance error: ${err}`, 'error');
      showAlert(`Maintenance error: ${err}`, 'danger');
    }
  } catch (err) {
    showAlert(`Error: ${err.message}`, 'danger');
  }
}
