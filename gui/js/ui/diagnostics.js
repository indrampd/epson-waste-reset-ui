import { el } from './dom.js';
import { getSelectedTarget } from '../state.js';
import { api } from '../api.js';
import { logToConsole, showAlert } from './logger.js';

function formatCounterKey(key) {
  return key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

function formatFatalCode(code) {
  if (typeof code === 'number') {
    const hex = code.toString(16).toUpperCase().padStart(2, '0');
    return `0x${hex} (${code})`;
  }
  return code ?? '-';
}

export async function readInfo() {
  const target = getSelectedTarget(el);
  logToConsole('Reading hardware diagnostics & internal counters...', 'info');

  try {
    const result = await api.getHardwareInfo(target);

    if (!result.ok) {
      logToConsole(`Failed to read info: ${result.error}`, 'error');
      showAlert(result.error || 'Gagal membaca informasi hardware.', 'danger');
      return;
    }

    const data = result.data || {};
    const counters = data.counters || [];
    const fatal = data.fatal_errors || [];

    const metaRows = [];
    if (data.serial) {
      metaRows.push(`<tr><td><code>Serial Number</code></td><td><strong>${data.serial}</strong></td></tr>`);
    }
    if (data.firmware) {
      metaRows.push(`<tr><td><code>Firmware Version</code></td><td><strong>${data.firmware}</strong></td></tr>`);
    }

    if (counters.length > 0 || metaRows.length > 0) {
      const counterRows = counters.map(c => `
        <tr>
          <td><code>${formatCounterKey(c.key)}</code></td>
          <td><strong>${c.value !== null && c.value !== undefined ? c.value.toLocaleString() : '-'}</strong></td>
        </tr>
      `);
      el.tbodyCounters.innerHTML = [...metaRows, ...counterRows].join('');
    } else {
      el.tbodyCounters.innerHTML = '<tr><td colspan="2" class="text-center">Tidak ada parameter terbaca.</td></tr>';
    }

    if (fatal.length > 0) {
      el.tbodyFatal.innerHTML = fatal.map(f => `
        <tr>
          <td>Slot ${f.slot}</td>
          <td>${f.kind}</td>
          <td><code>${formatFatalCode(f.code)}</code></td>
        </tr>
      `).join('');
    } else {
      el.tbodyFatal.innerHTML = '<tr><td colspan="3" class="text-center">Tidak ada catatan fatal error.</td></tr>';
    }

    logToConsole('Hardware info loaded.', 'success');
  } catch (err) {
    logToConsole(`Error reading info: ${err.message}`, 'error');
  }
}
