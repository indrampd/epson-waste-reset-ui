const { runEwr } = require('../services/ewrRunner');
const { broadcastEvent } = require('../services/sseService');
const { queryModels } = require('../services/databaseService');
const { listBackups, resolveBackupFilepath } = require('../services/backupService');

function readJsonBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      try {
        resolve(JSON.parse(body || '{}'));
      } catch (_) {
        resolve({});
      }
    });
  });
}

function appendTargetArgs(args, body) {
  if (body.interface !== undefined && body.interface !== null && body.interface !== '') {
    args.push('--interface', String(body.interface));
  }
  if (body.ip) args.push('--ip', String(body.ip));
  if (body.model) args.push('--model', String(body.model));
}

async function handleApiRequest(req, res, parsedUrl) {
  const { pathname, searchParams } = parsedUrl;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  try {
    if (pathname === '/api/devices' && req.method === 'GET') {
      const out = await runEwr(['--list']);
      const data = out.result?.data || { interfaces: [], network_printers: [] };
      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error: out.result?.error ?? null,
        interfaces: data.interfaces || [],
        network_printers: data.network_printers || []
      }));
    }

    if (pathname === '/api/status' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const args = ['--status', '--no-update'];
      appendTargetArgs(args, body);

      const out = await runEwr(args, (ev) => broadcastEvent({ stage: 'status', ...ev }));
      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error_code: out.result?.error_code ?? null,
        error: out.result?.error ?? (out.exitCode !== 0 ? out.rawStderr : null),
        data: out.result?.data ?? null,
        events: out.events
      }));
    }

    if (pathname === '/api/dry-run' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const args = ['--dry-run', '--no-update'];
      appendTargetArgs(args, body);
      if (body.target === 'cartridge') args.push('--cartridge');

      const out = await runEwr(args, (ev) => broadcastEvent({ stage: 'dry-run', ...ev }));
      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error_code: out.result?.error_code ?? null,
        error: out.result?.error ?? null,
        data: out.result?.data ?? null,
        events: out.events
      }));
    }

    if (pathname === '/api/reset' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const args = ['--no-update', body.force_yes ? '--force-yes' : '--yes'];
      appendTargetArgs(args, body);
      if (body.target === 'cartridge') args.push('--cartridge');

      broadcastEvent({ stage: 'reset_start', message: 'Starting EEPROM reset process...' });
      const out = await runEwr(args, (ev) => broadcastEvent({ stage: 'reset', ...ev }));
      broadcastEvent({ stage: 'reset_finish', ok: out.result?.ok ?? false });

      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error_code: out.result?.error_code ?? null,
        error: out.result?.error ?? null,
        data: out.result?.data ?? null,
        events: out.events
      }));
    }

    if (pathname === '/api/info' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const args = ['--info', '--no-update'];
      appendTargetArgs(args, body);

      const out = await runEwr(args, (ev) => broadcastEvent({ stage: 'info', ...ev }));
      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error_code: out.result?.error_code ?? null,
        error: out.result?.error ?? null,
        data: out.result?.data ?? null,
        events: out.events
      }));
    }

    if (pathname === '/api/maintenance' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const action = body.action || 'nozzle-check';
      const args = ['--no-update'];

      if (action === 'nozzle-check') {
        args.push('--nozzle-check');
        if (body.variant === 'alt') args.push('alt');
      } else if (action === 'head-clean') {
        args.push('--head-clean');
        if (body.level) args.push(body.level);
        if (body.cleanGroup) args.push('--clean-group', body.cleanGroup);
      } else if (action === 'power-clean') {
        args.push('--power-clean');
      }
      args.push(body.force_yes ? '--force-yes' : '--yes');
      appendTargetArgs(args, body);

      broadcastEvent({ stage: 'maintenance_start', action });
      const out = await runEwr(args, (ev) => broadcastEvent({ stage: 'maintenance', ...ev }));
      broadcastEvent({ stage: 'maintenance_finish', ok: out.result?.ok ?? false });

      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error_code: out.result?.error_code ?? null,
        error: out.result?.error ?? null,
        data: out.result?.data ?? null,
        events: out.events
      }));
    }

    if (pathname === '/api/models' && req.method === 'GET') {
      const q = searchParams.get('q') || '';
      const limit = parseInt(searchParams.get('limit') || '50', 10);
      const offset = parseInt(searchParams.get('offset') || '0', 10);
      return res.end(JSON.stringify(queryModels({ q, limit, offset })));
    }

    if (pathname === '/api/backups' && req.method === 'GET') {
      return res.end(JSON.stringify({ backups: listBackups() }));
    }

    if (pathname === '/api/dump' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const args = ['--dump', '--no-update'];
      appendTargetArgs(args, body);

      const out = await runEwr(args, (ev) => broadcastEvent({ stage: 'dump', ...ev }));
      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error_code: out.result?.error_code ?? null,
        error: out.result?.error ?? null,
        data: out.result?.data ?? null,
        events: out.events
      }));
    }

    if (pathname === '/api/restore' && req.method === 'POST') {
      const body = await readJsonBody(req);
      if (!body.filename) {
        return res.end(JSON.stringify({ ok: false, error: 'Filename is required' }));
      }
      const targetFilepath = resolveBackupFilepath(body.filename);
      if (!targetFilepath) {
        return res.end(JSON.stringify({ ok: false, error: 'Backup file not found in backup directories' }));
      }

      const args = ['--restore', targetFilepath, '--no-update', body.dryRun ? '--dry-run' : '--yes'];
      appendTargetArgs(args, body);

      const out = await runEwr(args, (ev) => broadcastEvent({ stage: 'restore', ...ev }));
      return res.end(JSON.stringify({
        ok: out.result?.ok ?? false,
        error_code: out.result?.error_code ?? null,
        error: out.result?.error ?? null,
        data: out.result?.data ?? null,
        events: out.events
      }));
    }

    res.writeHead(404);
    return res.end(JSON.stringify({ error: 'Endpoint not found' }));
  } catch (err) {
    res.writeHead(500);
    return res.end(JSON.stringify({ error: err.message }));
  }
}

module.exports = { handleApiRequest };
