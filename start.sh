#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== Epson Waste Reset UI ==="
echo "Based on RxNaison/Epson-Waste-Reset"

#Check if ewr binary exists
if [ ! -f "bin/ewr" ] && [ ! -f "bin/ewr.exe" ]; then
    echo "Warning: ewr binary not found in bin/."
fi

# On macOS, launch standalone Native App (SwiftUI + AppKit) directly unless --web is requested
if [ "$(uname)" = "Darwin" ] && [ -x "bin/ewr-gui-macos" ] && [ "${1:-}" != "--web" ]; then
    echo "Opening Native macOS App (SwiftUI/AppKit)..."
    exec ./bin/ewr-gui-macos
fi

# Fallback to Web UI Server (Node.js or Bun)
if command -v node >/dev/null 2>&1; then
    RUNTIME="node"
elif command -v bun >/dev/null 2>&1; then
    RUNTIME="bun"
else
    echo "Error: Node.js atau Bun diperlukan untuk menjalankan server Web UI."
    echo "Silakan install Node.js dari https://nodejs.org/"
    exit 1
fi

echo "Using runtime: $RUNTIME"

# Launch server in background if not running
if ! curl -s http://127.0.0.1:3827/api/devices >/dev/null 2>&1; then
    echo "Starting EWR Web UI Server on http://127.0.0.1:3827..."
    $RUNTIME server.js &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null || true" EXIT
    sleep 1
else
    echo "Server already running on port 3827."
fi

if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://127.0.0.1:3827"
    wait
elif command -v open >/dev/null 2>&1; then
    open "http://127.0.0.1:3827"
    wait
else
    echo "Buka browser Anda di: http://127.0.0.1:3827"
    wait
fi
