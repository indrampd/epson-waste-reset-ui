async function postJson(url, payload) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  return res.json();
}

export const api = {
  async getDevices() {
    const res = await fetch('/api/devices');
    return res.json();
  },
  getStatus(target) {
    return postJson('/api/status', target);
  },
  getDryRun(target) {
    return postJson('/api/dry-run', target);
  },
  resetCounter(payload) {
    return postJson('/api/reset', payload);
  },
  runMaintenance(payload) {
    return postJson('/api/maintenance', payload);
  },
  getHardwareInfo(target) {
    return postJson('/api/info', target);
  },
  async getBackups() {
    const res = await fetch('/api/backups');
    return res.json();
  },
  dumpBackup(target) {
    return postJson('/api/dump', target);
  },
  restoreBackup(payload) {
    return postJson('/api/restore', payload);
  },
  async searchModels(query = '', limit = 100) {
    const res = await fetch(`/api/models?q=${encodeURIComponent(query)}&limit=${limit}`);
    return res.json();
  },
  subscribeStream(onEvent) {
    const eventSource = new EventSource('/api/stream');
    eventSource.onmessage = (e) => {
      try {
        const data = JSON.parse(e.data);
        onEvent(data);
      } catch (_) {}
    };
    return eventSource;
  }
};
