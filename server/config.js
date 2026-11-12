const fs = require('fs');
const path = require('path');
const os = require('os');

const ROOT_DIR = path.resolve(__dirname, '..');
const PORT = Number(process.env.PORT) || 3827;
const HOST = process.env.HOST || '127.0.0.1';

const BIN_DIR = path.join(ROOT_DIR, 'bin');
const EWR_BIN = process.platform === 'win32'
  ? path.join(BIN_DIR, 'ewr.exe')
  : path.join(BIN_DIR, 'ewr');
const DB_PATH = path.join(BIN_DIR, 'database.json');
const GUI_DIR = path.join(ROOT_DIR, 'gui');

const BACKUP_DIRS = [
  path.join(BIN_DIR, 'backups'),
  path.join(ROOT_DIR, 'backups'),
  path.join(os.homedir(), 'Library', 'Application Support', 'EWR', 'backups'),
  path.join(os.homedir(), '.local', 'share', 'ewr', 'backups')
];

function ensureBackupDirectories() {
  for (const dir of [BACKUP_DIRS[0], BACKUP_DIRS[1]]) {
    if (!fs.existsSync(dir)) {
      try {
        fs.mkdirSync(dir, { recursive: true });
      } catch (_) {}
    }
  }
}

module.exports = {
  ROOT_DIR,
  PORT,
  HOST,
  BIN_DIR,
  EWR_BIN,
  DB_PATH,
  GUI_DIR,
  BACKUP_DIRS,
  ensureBackupDirectories
};
