const fs = require('fs');
const path = require('path');
const { BACKUP_DIRS } = require('../config');

function listBackups() {
  const fileMap = new Map();
  for (const dir of BACKUP_DIRS) {
    try {
      if (!fs.existsSync(dir)) continue;
      const list = fs.readdirSync(dir);
      for (const filename of list) {
        if (!filename.endsWith('.json') && !filename.endsWith('.txt')) continue;
        if (fileMap.has(filename)) continue;
        const filepath = path.join(dir, filename);
        const stat = fs.statSync(filepath);
        fileMap.set(filename, {
          filename,
          filepath,
          size: stat.size,
          created: stat.mtime
        });
      }
    } catch (_) {}
  }
  return Array.from(fileMap.values()).sort((a, b) => b.created - a.created);
}

function resolveBackupFilepath(filename) {
  const safeFile = path.basename(String(filename));
  for (const dir of BACKUP_DIRS) {
    const candidate = path.join(dir, safeFile);
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

module.exports = {
  listBackups,
  resolveBackupFilepath
};
