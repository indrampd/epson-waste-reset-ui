import { el } from './ui/dom.js';
import { state } from './state.js';
import { applyLanguage } from './i18n.js';
import { api } from './api.js';
import { setTheme, logToConsole, hideAlert } from './ui/logger.js';
import {
  scanDevices,
  handleDeviceSelectionChange,
  readStatus,
  renderStatusData,
  executeDryRun,
  openResetModal,
  executeReset,
  updateResetStepFromEvent
} from './ui/dashboard.js';
import { runMaintenance } from './ui/maintenance.js';
import { readInfo } from './ui/diagnostics.js';
import { loadBackups, restoreBackup, dumpEepromBackup } from './ui/backups.js';
import { searchModels, selectModelFromDb } from './ui/database.js';

// Expose inline onclick handlers used by rendered table rows
window.restoreBackup = restoreBackup;
window.dumpEepromBackup = dumpEepromBackup;
window.selectModelFromDb = selectModelFromDb;

function setLanguage(lang) {
  state.currentLang = lang;
  applyLanguage(lang, el.langBtns);
  if (state.currentStatusData) {
    renderStatusData(state.currentStatusData);
  }
}

function setupEventStream() {
  api.subscribeStream((data) => {
    if (data.stage === 'reset' && data.code) {
      updateResetStepFromEvent(data.code);
      logToConsole(`[Reset Event] ${data.code}: ${data.message || ''}`, 'event');
    } else if (data.stage === 'maintenance') {
      logToConsole(`[Maintenance Event] ${data.code || ''}: ${data.message || ''}`, 'event');
    } else if (data.stage) {
      logToConsole(`[${data.stage}] ${data.message || ''}`, 'event');
    }
  });
}

function initEventListeners() {
  let searchDebounce = null;

  el.themeToggle.addEventListener('click', () => {
    const nextTheme = state.currentTheme === 'dark' ? 'light' : 'dark';
    setTheme(nextTheme);
  });

  el.langBtns.forEach(btn => {
    btn.addEventListener('click', () => setLanguage(btn.dataset.lang));
  });

  el.tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      el.tabs.forEach(t => t.classList.remove('active'));
      el.tabPanels.forEach(p => p.classList.remove('active'));

      tab.classList.add('active');
      const targetPanel = document.getElementById(tab.dataset.tab);
      if (targetPanel) targetPanel.classList.add('active');

      if (tab.dataset.tab === 'tab-backup') loadBackups();
      if (tab.dataset.tab === 'tab-database') searchModels(el.inputDbSearch.value.trim());
    });
  });

  el.selectDevice.addEventListener('change', handleDeviceSelectionChange);
  el.btnRefreshDevices.addEventListener('click', scanDevices);
  el.btnReadStatus.addEventListener('click', readStatus);
  el.btnRefreshCounters.addEventListener('click', readStatus);
  el.btnCloseAlert.addEventListener('click', hideAlert);

  el.btnOpenDryRun.addEventListener('click', executeDryRun);
  el.btnCloseDryRun.addEventListener('click', () => el.modalDryRun.classList.add('hidden'));
  el.btnCancelDryRun.addEventListener('click', () => el.modalDryRun.classList.add('hidden'));
  el.btnProceedFromDryRun.addEventListener('click', () => {
    el.modalDryRun.classList.add('hidden');
    openResetModal();
  });

  el.btnOpenReset.addEventListener('click', openResetModal);
  el.btnCloseReset.addEventListener('click', () => el.modalReset.classList.add('hidden'));
  el.btnCancelReset.addEventListener('click', () => el.modalReset.classList.add('hidden'));
  el.chkConfirmPowerCycle.addEventListener('change', (e) => {
    el.btnConfirmReset.disabled = !e.target.checked;
  });
  el.btnConfirmReset.addEventListener('click', executeReset);

  el.btnMaintNozzle.addEventListener('click', () => runMaintenance('nozzle-check'));
  el.btnMaintClean.addEventListener('click', () => runMaintenance('head-clean'));
  el.btnMaintPower.addEventListener('click', () => runMaintenance('power-clean'));

  el.btnReadInfo.addEventListener('click', readInfo);
  el.btnRefreshBackups.addEventListener('click', loadBackups);

  el.inputDbSearch.addEventListener('input', (e) => {
    clearTimeout(searchDebounce);
    searchDebounce = setTimeout(() => {
      searchModels(e.target.value.trim());
    }, 250);
  });

  el.btnToggleConsole.addEventListener('click', () => {
    el.consoleDrawer.classList.toggle('collapsed');
    el.btnToggleConsole.textContent = el.consoleDrawer.classList.contains('collapsed') ? 'Buka' : 'Tutup';
  });
  el.btnClearConsole.addEventListener('click', () => {
    el.consoleOutput.innerHTML = '';
  });
}

document.addEventListener('DOMContentLoaded', () => {
  setLanguage(state.currentLang);
  setTheme(state.currentTheme);
  initEventListeners();
  setupEventStream();

  scanDevices().then(() => {
    setTimeout(readStatus, 500);
  });
});
