#!/usr/bin/env node
const http = require('http');
const { PORT, HOST, ensureBackupDirectories } = require('./server/config');
const { handleSseConnection } = require('./server/services/sseService');
const { handleApiRequest } = require('./server/routes/apiRouter');
const { serveStaticGui } = require('./server/middleware/staticServer');

ensureBackupDirectories();

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const { pathname } = parsedUrl;

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (pathname === '/api/stream') {
    handleSseConnection(req, res);
    return;
  }

  if (pathname.startsWith('/api/')) {
    await handleApiRequest(req, res, parsedUrl);
    return;
  }

  serveStaticGui(req, res, pathname);
});

server.listen(PORT, HOST, () => {
  console.log(`[EWR UI] Server running at http://${HOST}:${PORT}`);
});
