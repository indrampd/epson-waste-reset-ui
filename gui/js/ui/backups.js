import { el } from './dom.js';
import { state, getSelectedTarget } from '../state.js';
import { api } from '../api.js';
import { logToConsole, showAlert } from './logger.js';
import { readStatus } from './dashboard.js';

export async function loadBackups() {
  try {
    const data = await api.getBackups();
    const list = data.backups || [];

    if (list.length === 0) {
      el.tbodyBackups.innerHTML = '<tr><td colspan="4" class="text-center">Belum ada file backup tersimpan di folder backups/.</td></tr>';
      return;
    }

    el.tbodyBackups.innerHTML = list.map(b => {
      const dateStr = new Date(b.created).toLocaleString();
      const kb = (b.size / 1024).toFixed(1) + ' KB';
      return `
        <tr>
          <td><code>${b.filename}</code></td>
          <td>${kb}</td>
          <td>${dateStr}</td>
          <td>
            <button class="btn btn-xs btn-outline" onclick="restoreBackup('${b.filename}', true)">Dry Run</button>
            <button class="btn btn-xs btn-primary" onclick="restoreBackup('${b.filename}', false)">Restore</button>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    logToConsole(`Error loading backups: ${err.message}`, 'error');
  }
}

export async function dumpEepromBackup() {
  const target = getSelectedTarget(el);
  logToConsole('Dumping EEPROM backup (ewr --dump)...', 'info');

  try {
    const result = await api.dumpBackup(target);
    if (result.ok) {
      await loadBackups();
      const msg = state.currentLang === 'id' ? 'Backup EEPROM berhasil disimpan.' : 'EEPROM backup saved successfully.';
      logToConsole(msg, 'success');
      showAlert(msg, 'success');
    } else {
      const err = result.error || result.error_code || 'EEPROM dump failed';
      logToConsole(`Dump failed: ${err}`, 'error');
      showAlert(err, 'danger');
    }
  } catch (err) {
    showAlert(`Error: ${err.message}`, 'danger');
  }
}

export async function restoreBackup(filename, dryRun = false) {
  if (!dryRun) {
    const confirmed = confirm(
      state.currentLang === 'id'
        ? `Kembalikan nilai counter printer dari file backup "${filename}"?`
        : `Restore printer counter values from backup file "${filename}"?`
    );
    if (!confirmed) return;
  }

  const target = getSelectedTarget(el);
  logToConsole(`${dryRun ? 'Simulating' : 'Restoring'} EEPROM from backup ${filename}...`, 'warn');

  try {
    const result = await api.restoreBackup({ ...target, filename, dryRun });

    if (result.ok) {
      if (dryRun) {
        const msg = state.currentLang === 'id'
          ? `Simulasi restore valid untuk "${filename}".`
          : `Restore dry-run succeeded for "${filename}".`;
        logToConsole(msg, 'success');
        showAlert(msg, 'success');
      } else {
        alert(state.currentLang === 'id' ? 'Restore berhasil! Silakan matikan dan nyalakan printer kembali.' : 'Restore successful! Please power cycle the printer.');
        logToConsole('Restore verified successfully.', 'success');
        readStatus();
      }
    } else {
      const err = result.error || result.error_code || 'Restore failed';
      logToConsole(`Restore failed: ${err}`, 'error');
      showAlert(`Gagal restore: ${err}`, 'danger');
    }
  } catch (err) {
    showAlert(`Error: ${err.message}`, 'danger');
  }
}
