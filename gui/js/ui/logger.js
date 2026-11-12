import { el } from './dom.js';
import { state } from '../state.js';

export function setTheme(theme) {
  state.currentTheme = theme;
  localStorage.setItem('ewr_theme', theme);
  document.documentElement.setAttribute('data-theme', theme);
}

export function logToConsole(message, type = 'info') {
  const line = document.createElement('div');
  line.className = `log-line ${type}`;
  const now = new Date().toTimeString().split(' ')[0];
  line.textContent = `[${now}] ${message}`;
  el.consoleOutput.appendChild(line);
  el.consoleOutput.scrollTop = el.consoleOutput.scrollHeight;
}

export function showAlert(message, type = 'info') {
  el.alertBanner.className = `alert-banner ${type}`;
  el.alertMessage.textContent = message;
  el.alertBanner.classList.remove('hidden');
}

export function hideAlert() {
  el.alertBanner.classList.add('hidden');
}

export function updateConnectionState(connected, label) {
  const dot = el.connectionStatus.querySelector('.status-dot');
  dot.className = `status-dot ${connected ? 'connected' : 'disconnected'}`;
  el.statusBadgeText.textContent = label;
}
