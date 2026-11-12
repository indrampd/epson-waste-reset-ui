import { el } from './dom.js';
import { state } from '../state.js';
import { api } from '../api.js';
import { logToConsole, showAlert } from './logger.js';

export async function searchModels(query = '') {
  try {
    const data = await api.searchModels(query, 100);
    const models = data.models || [];

    el.dbTotalCount.textContent = `${data.total} printer terdaftar`;

    if (models.length === 0) {
      el.tbodyModels.innerHTML = '<tr><td colspan="6" class="text-center">Tidak ada model yang cocok.</td></tr>';
      return;
    }

    el.tbodyModels.innerHTML = models.map(m => {
      const aliases = m.aliases && m.aliases.length > 0 ? m.aliases.join(', ') : '-';
      const cleanings = m.cleaningLevels && m.cleaningLevels.length > 0 ? m.cleaningLevels.join(', ') : 'ESC/P2 Print';
      const keys = `rkey: ${m.rkey || '-'} / wkey: ${m.wkey || '-'}`;
      const badgeLabel = m.isKeyless ? 'Keyless' : (m.hasPadGroups ? 'Resettable' : 'Partial');

      return `
        <tr>
          <td><strong>${m.name}</strong></td>
          <td class="text-muted" style="max-width: 250px;">${aliases}</td>
          <td><span class="badge ${m.hasPadGroups ? 'safe' : 'warn'}">${badgeLabel}</span></td>
          <td>${cleanings}</td>
          <td><code>${keys}</code></td>
          <td>
            <button class="btn btn-xs btn-primary" onclick="selectModelFromDb('${m.name}')">Pilih</button>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    logToConsole(`Error searching models: ${err.message}`, 'error');
  }
}

export function selectModelFromDb(modelName) {
  el.inputModelOverride.value = modelName;
  document.querySelector('.tab-btn[data-tab="tab-dashboard"]').click();
  showAlert(
    state.currentLang === 'id' ? `Model "${modelName}" dipilih.` : `Model "${modelName}" selected.`,
    'info'
  );
}
