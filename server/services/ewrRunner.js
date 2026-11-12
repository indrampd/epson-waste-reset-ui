const { spawn } = require('child_process');
const { ROOT_DIR, EWR_BIN } = require('../config');

/**
 * Execute bin/ewr with `--json` and parse newline-delimited JSON stream.
 */
function runEwr(args, onEvent = null) {
  return new Promise((resolve) => {
    const fullArgs = [...args, '--json'];
    const proc = spawn(EWR_BIN, fullArgs, {
      cwd: ROOT_DIR,
      env: { ...process.env, NO_COLOR: '1' }
    });

    let stdout = '';
    let stderr = '';
    let resultObj = null;
    let helloObj = null;
    const events = [];

    let lineBuffer = '';
    proc.stdout.on('data', (chunk) => {
      stdout += chunk;
      lineBuffer += chunk.toString('utf8');
      const lines = lineBuffer.split('\n');
      lineBuffer = lines.pop();

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        try {
          const parsed = JSON.parse(trimmed);
          if (parsed.type === 'hello') {
            helloObj = parsed;
          } else if (parsed.type === 'event') {
            events.push(parsed);
            if (onEvent) onEvent(parsed);
          } else if (parsed.type === 'result') {
            resultObj = parsed;
          }
        } catch (_) {}
      }
    });

    proc.stderr.on('data', (chunk) => {
      stderr += chunk;
    });

    proc.on('close', (code) => {
      if (lineBuffer.trim()) {
        try {
          const parsed = JSON.parse(lineBuffer.trim());
          if (parsed.type === 'result') resultObj = parsed;
          else if (parsed.type === 'event') events.push(parsed);
        } catch (_) {}
      }

      resolve({
        exitCode: code,
        hello: helloObj,
        result: resultObj,
        events,
        rawStdout: stdout,
        rawStderr: stderr
      });
    });

    proc.on('error', (err) => {
      resolve({
        exitCode: -1,
        hello: null,
        result: {
          ok: false,
          error_code: 'spawn_failed',
          error: err.message,
          data: {}
        },
        events: [],
        rawStdout: '',
        rawStderr: err.stack || err.message
      });
    });
  });
}

module.exports = { runEwr };
