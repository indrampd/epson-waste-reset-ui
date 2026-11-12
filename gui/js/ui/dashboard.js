import { el } from './dom.js';
import { state, getSelectedTarget, getManualTankLevel, setManualTankLevel } from '../state.js';
import { api } from '../api.js';
import { logToConsole, showAlert, hideAlert, updateConnectionState } from './logger.js';

function parseDeviceIdModel(devId) {
  const match = devId.match(/MDL:([^;]+)/);
  return match ? match[1] : 'Epson Device';
}

export function handleDeviceSelectionChange() {
  const selectedOpt = el.selectDevice.selectedOptions[0];
  if (!selectedOpt) return;

  const model = selectedOpt.dataset.model;
  if (model && !el.inputModelOverride.value.trim()) {
    el.inputModelOverride.value = model;
  }

  const isUsb = selectedOpt.value.startsWith('usb:');
  const isNet = selectedOpt.value.startsWith('ip:');

  el.valPrinterConn.textContent = isUsb ? 'USB (Direct)' : (isNet ? 'Network (LAN/Wi-Fi)' : '-');
  if (selectedOpt.dataset.deviceid) {
    el.valDeviceId.textContent = selectedOpt.dataset.deviceid;
  }

  updateConnectionState(true, selectedOpt.textContent.split('[')[0].trim());
}

export async function scanDevices() {
  el.statusBadgeText.textContent = state.currentLang === 'id' ? 'Memindai...' : 'Scanning...';
  logToConsole('Scanning USB interfaces and network printers...', 'info');

  try {
    const data = await api.getDevices();
    el.selectDevice.innerHTML = '';

    if (!data.ok && data.error) {
      logToConsole(`Scan notice: ${data.error}`, 'warn');
    }

    const interfaces = data.interfaces || [];
    const netPrinters = data.network_printers || [];

    if (interfaces.length === 0 && netPrinters.length === 0) {
      const opt = document.createElement('option');
      opt.value = '';
      opt.textContent = state.currentLang === 'id' ? 'Tidak ada printer terdeteksi' : 'No printer detected';
      el.selectDevice.appendChild(opt);
      updateConnectionState(false, 'Tidak Terhubung');
      return;
    }

    if (interfaces.length > 0) {
      const groupUsb = document.createElement('optgroup');
      groupUsb.label = 'USB Interfaces';

      interfaces.forEach(item => {
        const opt = document.createElement('option');
        opt.value = `usb:${item.index}`;
        const modelName = item.model_match || (item.device_id ? parseDeviceIdModel(item.device_id) : 'Epson Printer');
        opt.textContent = `USB: ${modelName} [if_${item.interface_number ?? item.index}]`;
        opt.dataset.model = item.model_match || '';
        opt.dataset.deviceid = item.device_id || '';
        groupUsb.appendChild(opt);
      });
      el.selectDevice.appendChild(groupUsb);
    }

    if (netPrinters.length > 0) {
      const groupNet = document.createElement('optgroup');
      groupNet.label = 'Network (LAN / Wi-Fi)';

      netPrinters.forEach(item => {
        const opt = document.createElement('option');
        opt.value = `ip:${item.address}`;
        opt.textContent = `LAN: ${item.reported_model || item.model_match || 'Epson'} (${item.address})`;
        opt.dataset.model = item.model_match || '';
        groupNet.appendChild(opt);
      });
      el.selectDevice.appendChild(groupNet);
    }

    if (el.selectDevice.options.length > 0) {
      el.selectDevice.selectedIndex = 0;
      handleDeviceSelectionChange();
    }

    logToConsole(`Found ${interfaces.length} USB interface(s) and ${netPrinters.length} network printer(s).`, 'success');
  } catch (err) {
    logToConsole(`Error scanning devices: ${err.message}`, 'error');
    updateConnectionState(false, 'Gagal Memindai');
  }
}

export function renderStatusData(data) {
  if (!data) return;

  el.valPrinterName.textContent = data.detected_model || data.model || '-';
  if (data.model && !el.inputModelOverride.value.trim()) {
    el.inputModelOverride.value = data.model;
  }

  const printerState = data.printer?.state || 'READY';
  el.badgePrinterState.textContent = printerState;
  el.badgePrinterState.className = `badge ${printerState === 'READY' || printerState === 'IDLE' ? 'ready' : (printerState === 'ERROR' ? 'error' : 'warn')}`;

  const printerError = data.printer?.error;
  el.valPrinterCondition.textContent = printerError ? `Error: ${printerError}` : (state.currentLang === 'id' ? 'Normal / Siap' : 'Normal / Ready');

  const pads = data.pads || [];
  const mainPad = pads.find(p => p.kind === 'main') || pads[0];
  const platenPad = pads.find(p => p.kind === 'platen') || (pads.length > 1 ? pads[1] : null);

  if (mainPad) {
    const used = mainPad.used ?? 0;
    const max = mainPad.max ?? 6346;
    const pct = mainPad.percent ?? Math.round((used / max) * 100);

    el.valMainPadRaw.textContent = `${used.toLocaleString()} / ${max.toLocaleString()} ${state.currentLang === 'id' ? 'poin' : 'points'}`;
    el.valMainPadPct.textContent = `${pct}%`;
    el.barMainPad.style.width = `${Math.min(pct, 100)}%`;

    const statusClass = pct >= 100 ? 'crit' : (pct >= 80 ? 'warn' : 'safe');
    el.valMainPadPct.className = `counter-pct ${statusClass}`;
    el.barMainPad.className = `gauge-bar-fill ${statusClass}`;
  }

  if (platenPad) {
    el.platenPadBlock.classList.remove('hidden');
    const used = platenPad.used ?? 0;
    const max = platenPad.max ?? 3416;
    const pct = platenPad.percent ?? Math.round((used / max) * 100);

    el.valPlatenPadRaw.textContent = `${used.toLocaleString()} / ${max.toLocaleString()} ${state.currentLang === 'id' ? 'poin' : 'points'}`;
    el.valPlatenPadPct.textContent = `${pct}%`;
    el.barPlatenPad.style.width = `${Math.min(pct, 100)}%`;

    const statusClass = pct >= 100 ? 'crit' : (pct >= 80 ? 'warn' : 'safe');
    el.valPlatenPadPct.className = `counter-pct ${statusClass}`;
    el.barPlatenPad.className = `gauge-bar-fill ${statusClass}`;
  } else {
    el.platenPadBlock.classList.add('hidden');
  }

  // Ink levels: automatic IC-chip sensor OR EcoTank visual calibration
  const inks = data.printer?.inks || [];
  if (inks.length > 0) {
    el.inksSection.classList.remove('hidden');
    el.inksGrid.innerHTML = '';

    const isTankMode = inks.every(i => i.level === null || i.level === undefined);
    const titleEl = document.getElementById('t-ink-levels-title');
    if (titleEl) {
      if (isTankMode) {
        titleEl.textContent = state.currentLang === 'id'
          ? 'Estimasi Level Tinta EcoTank (Kalibrasi Visual Tabung - Klik untuk Ubah)'
          : 'EcoTank Ink Level Estimates (Visual Tank Calibration - Click to Adjust)';
      } else {
        titleEl.textContent = state.currentLang === 'id'
          ? 'Estimasi Level Tinta Cartridge (Sensor Chip IC)'
          : 'Cartridge Ink Level Estimates (IC Chip Sensor)';
      }
    }

    inks.forEach(ink => {
      const color = ink.color || 'Ink';
      const isVisual = ink.level === null || ink.level === undefined;
      const effectiveLevel = isVisual ? getManualTankLevel(color) : ink.level;
      const label = isVisual ? `~${effectiveLevel}%` : `${effectiveLevel}%`;

      const card = document.createElement('div');
      card.className = 'ink-card';
      if (isVisual) {
        card.style.cursor = 'pointer';
        card.title = state.currentLang === 'id'
          ? 'Klik untuk menyesuaikan level visual tabung (20% - 100%)'
          : 'Click to cycle visual tank level (20% - 100%)';
        card.addEventListener('click', () => {
          const steps = [20, 40, 60, 80, 100];
          const nextIdx = (steps.indexOf(effectiveLevel) + 1) % steps.length;
          setManualTankLevel(color, steps[nextIdx]);
          renderStatusData(state.currentStatusData);
        });
      }

      card.innerHTML = `
        <div class="ink-name">${color}</div>
        <div class="ink-level-val">${label}</div>
      `;
      el.inksGrid.appendChild(card);
    });
  } else {
    el.inksSection.classList.add('hidden');
  }
}

export async function readStatus() {
  hideAlert();
  const target = getSelectedTarget(el);
  logToConsole(`Querying printer counter status (${target.model || 'Auto'})...`, 'info');

  el.btnReadStatus.disabled = true;
  el.btnRefreshCounters.disabled = true;

  try {
    const result = await api.getStatus(target);

    if (!result.ok) {
      const err = result.error || result.error_code || 'Gagal membaca status printer.';
      logToConsole(`Read status failed: ${err}`, 'error');
      showAlert(err, 'danger');
      return;
    }

    state.currentStatusData = result.data;
    renderStatusData(state.currentStatusData);
    logToConsole('Counter status updated successfully.', 'success');
  } catch (err) {
    logToConsole(`Network error reading status: ${err.message}`, 'error');
    showAlert(`Error: ${err.message}`, 'danger');
  } finally {
    el.btnReadStatus.disabled = false;
    el.btnRefreshCounters.disabled = false;
  }
}

export async function executeDryRun() {
  const target = getSelectedTarget(el);
  logToConsole('Running EEPROM reset simulation (Dry Run)...', 'info');

  el.dryrunPlanContainer.innerHTML = '<span class="text-muted">Memuat rencana simulasi penulisan EEPROM...</span>';
  el.modalDryRun.classList.remove('hidden');

  try {
    const result = await api.getDryRun(target);

    if (!result.ok) {
      el.dryrunPlanContainer.innerHTML = `<span class="text-danger">Gagal menjalankan dry-run: ${result.error || result.error_code}</span>`;
      logToConsole(`Dry run failed: ${result.error}`, 'error');
      return;
    }

    const data = result.data || {};
    const plannedWrites = data.planned_writes || [];
    const covers = data.reset_covers || [];

    let html = `<div><strong>Model:</strong> ${data.model || target.model}</div>`;
    html += `<div style="margin: 0.5rem 0;"><strong>Bantalan yang Dicakup:</strong> ${covers.map(c => `${c.name} (${c.kind})`).join(', ') || 'Semua Bantalan Reset'}</div>`;
    html += `<div style="margin-top: 0.75rem;"><strong>Daftar Alamat EEPROM & Nilai Reset (${plannedWrites.length} register):</strong></div>`;

    html += '<table class="data-table" style="margin-top: 0.5rem;"><thead><tr><th>Alamat (Address)</th><th>Nilai Baru (Hex/Dec)</th></tr></thead><tbody>';
    plannedWrites.forEach(w => {
      const hex = '0x' + w.value.toString(16).toUpperCase().padStart(2, '0');
      html += `<tr><td>Register ${w.address} (0x${w.address.toString(16).toUpperCase()})</td><td>${w.value} (${hex})</td></tr>`;
    });
    html += '</tbody></table>';

    el.dryrunPlanContainer.innerHTML = html;
    logToConsole(`Simulation generated ${plannedWrites.length} planned register writes.`, 'success');
  } catch (err) {
    el.dryrunPlanContainer.innerHTML = `<span class="text-danger">Error: ${err.message}</span>`;
  }
}

export function setStepState(stepId, stepState) {
  const item = document.getElementById(stepId);
  if (item) {
    item.className = `step-item ${stepState}`;
  }
}

export function updateResetStepFromEvent(code = '') {
  const c = String(code).toLowerCase();
  if (c.includes('backup')) {
    setStepState('step-preflight', 'done');
    setStepState('step-backup', 'active');
  } else if (c.includes('write') || c.includes('reset')) {
    setStepState('step-preflight', 'done');
    setStepState('step-backup', 'done');
    setStepState('step-write', 'active');
  } else if (c.includes('verify') || c.includes('read')) {
    setStepState('step-preflight', 'done');
    setStepState('step-backup', 'done');
    setStepState('step-write', 'done');
    setStepState('step-verify', 'active');
  }
}

export function openResetModal() {
  const target = getSelectedTarget(el);
  el.modalResetModel.textContent = target.model || (el.valPrinterName.textContent !== '-' ? el.valPrinterName.textContent : 'Otomatis');
  el.modalResetConn.textContent = el.valPrinterConn.textContent;

  el.chkConfirmPowerCycle.checked = false;
  el.btnConfirmReset.disabled = true;

  el.resetConfirmState.classList.remove('hidden');
  el.resetProgressState.classList.add('hidden');
  el.modalResetFooter.classList.remove('hidden');
  el.resetResultBox.classList.add('hidden');

  ['step-preflight', 'step-backup', 'step-write', 'step-verify'].forEach(id => {
    setStepState(id, '');
  });

  el.modalReset.classList.remove('hidden');
}

export async function executeReset() {
  const target = getSelectedTarget(el);

  el.resetConfirmState.classList.add('hidden');
  el.modalResetFooter.classList.add('hidden');
  el.resetProgressState.classList.remove('hidden');

  logToConsole('Initiating Waste Ink Pad Counter reset...', 'warn');
  setStepState('step-preflight', 'active');

  try {
    const result = await api.resetCounter({ ...target, force_yes: false });

    if (result.ok) {
      setStepState('step-preflight', 'done');
      setStepState('step-backup', 'done');
      setStepState('step-write', 'done');
      setStepState('step-verify', 'done');
    }

    el.resetResultBox.classList.remove('hidden');

    if (result.ok) {
      el.resetResultBox.className = 'reset-result-box success';
      el.resetResultBox.innerHTML = `
        <strong>RESET BERHASIL / SUCCESS!</strong>
        <p style="margin-top: 0.35rem;">
          Register EEPROM telah berhasil di-reset ke 0% dan diverifikasi oleh hardware.<br>
          <strong>LANGKAH WAJIB BERIKUTNYA:</strong> Matikan printer menggunakan tombol Power fisik, lalu nyalakan kembali.
        </p>
      `;
      logToConsole('EEPROM reset completed and verified by hardware.', 'success');
      setTimeout(readStatus, 1500);
    } else {
      el.resetResultBox.className = 'reset-result-box error';
      el.resetResultBox.innerHTML = `
        <strong>RESET GAGAL:</strong>
        <p style="margin-top: 0.35rem;">${result.error || result.error_code || 'Terjadi kesalahan saat menulis EEPROM.'}</p>
      `;
      logToConsole(`Reset error: ${result.error || result.error_code}`, 'error');
    }
  } catch (err) {
    el.resetResultBox.className = 'reset-result-box error';
    el.resetResultBox.innerHTML = `<strong>Error:</strong> ${err.message}`;
    logToConsole(`Network error during reset: ${err.message}`, 'error');
  }
}
