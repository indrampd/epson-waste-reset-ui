const fs = require('fs');
const { DB_PATH } = require('../config');

let cachedModels = null;

function loadModelsDatabase() {
  if (cachedModels) return cachedModels;
  try {
    if (fs.existsSync(DB_PATH)) {
      const raw = fs.readFileSync(DB_PATH, 'utf8');
      const data = JSON.parse(raw);
      const specs = data.specs || {};
      const modelsObj = data.models || {};
      const keylessObj = data.keyless_models || {};
      const models = [];

      for (const [name, rawInfo] of Object.entries(modelsObj)) {
        const specInfo = (rawInfo.spec && specs[rawInfo.spec]) ? specs[rawInfo.spec] : {};
        const info = { ...specInfo, ...rawInfo };
        models.push({
          name,
          aliases: info.aliases || [],
          hasPadGroups: Array.isArray(info.pad_groups) && info.pad_groups.length > 0,
          isKeyless: false,
          cleaningLevels: info.cleaning?.clean ? Object.keys(info.cleaning.clean) : [],
          hasPowerClean: Boolean(info.cleaning?.charge),
          rkey: info.rkey ?? null,
          wkey: info.wkey ?? null
        });
      }

      for (const [name, info] of Object.entries(keylessObj)) {
        if (modelsObj[name]) continue;
        models.push({
          name,
          aliases: info.aliases || [],
          hasPadGroups: Array.isArray(info.pad_groups) && info.pad_groups.length > 0,
          isKeyless: true,
          cleaningLevels: [],
          hasPowerClean: false,
          rkey: 'Keyless',
          wkey: 'Keyless'
        });
      }

      models.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }));
      cachedModels = models;
      return cachedModels;
    }
  } catch (err) {
    console.error('[EWR Database] Failed to load database.json:', err.message);
  }
  return [];
}

function queryModels({ q = '', limit = 50, offset = 0 }) {
  const models = loadModelsDatabase();
  const normalized = String(q).trim().toLowerCase();
  const filtered = normalized
    ? models.filter(m =>
        m.name.toLowerCase().includes(normalized) ||
        m.aliases.some(a => a.toLowerCase().includes(normalized))
      )
    : models;

  return {
    total: filtered.length,
    models: filtered.slice(offset, offset + limit)
  };
}

module.exports = {
  loadModelsDatabase,
  queryModels
};
