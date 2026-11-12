# Repository Guidelines

## Project Overview
Epson Waste Ink Pad Counter reset and maintenance utility. It provides tools to read and reset waste ink pad counters, perform printhead cleanings, run nozzle checks, and backup/restore EEPROM data on Epson inkjet printers using the IEEE 1284.4 D4 packet protocol over USB and SNMP over LAN.

The repository accommodates two modular execution models:
1. A standalone **native macOS desktop application** (`native/` → `bin/ewr-gui-macos` & `Epson Waste Reset.app`) built with **SwiftUI + AppKit (`Cocoa`)** (no WebKit or Node.js dependency) that invokes `bin/ewr` directly and loads `bin/database.json`.
2. A cross-platform **web suite** powered by a modular Node.js backend (`server.js` + `server/`) and an ES-module web frontend (`gui/`), backed by `bin/ewr`.

---

## Architecture & Data Flow

### Core Components
```text
[ Web Browser (gui/js/* ES Modules) ]      [ Native macOS App (native/Views/* SwiftUI) ]
                 │                                               │
                 ▼ (HTTP REST / SSE :3827)                       ▼ (EWRViewModel -> EWRProcessRunner)
      [ server.js + server/* ]                                   │
                 │                                               │
                 └───────────────────────┬───────────────────────┘
                                         ▼ (spawns with --json / NDJSON stdout)
                                  [ bin/ewr ] ──────────────► [ Physical Epson Printer ]
                                  (vendored binary)            (IEEE 1284.4 D4 USB / SNMP)
```

### Core Binaries
- **`bin/ewr`**: Precompiled Mach-O universal binary vendored from upstream (`RxNaison/Epson-Waste-Reset`). Both `server/services/ewrRunner.js` and `native/Services/EWRProcessRunner.swift` shell out exclusively to `bin/ewr`.
- **`bin/ewr-gui-macos`** (and `Epson Waste Reset.app`): Standalone native macOS GUI compiled from `native/**/*.swift` (`SwiftUI` + `Cocoa`).

### Data Flow
1. **Native macOS Execution**: `bin/ewr-gui-macos` initializes `AppDelegate` (`native/App/AppDelegate.swift`), hosting `MainContentView` bound to `EWRViewModel` (`native/ViewModels/EWRViewModel.swift`). It loads `bin/database.json` via `DatabaseService`, scans `backups/`, and spawns `bin/ewr --json` via `EWRProcessRunner` to stream live NDJSON events into the UI.
2. **Web UI Execution**: `./start.sh --web` (or `node server.js`) starts the HTTP/SSE server on port `3827`.
3. **Device Discovery**: `bin/ewr --list --json` enumerates detected USB interfaces and network printers.
4. **Operations & Streaming**: Status reads, dry-runs, resets, and maintenance invoke `bin/ewr` with `--json`, `--no-update`, and action-specific flags (`--yes`/`--force-yes`).
5. **NDJSON Events**: `bin/ewr` emits newline-delimited JSON (`hello`, `event`, `result`). Both `EWRProcessRunner.swift` (via `FileHandle.readabilityHandler`) and `ewrRunner.js` + `sseService.js` (via SSE `/api/stream`) stream these events in real time.
6. **Database Resolution**: Both `native/Services/DatabaseService.swift` and `server/services/databaseService.js` resolve model `spec` inheritance against `specs` in `bin/database.json` (~1464 total models including `keyless_models`).

---

## Key Directories

- `native/`: Modular Swift source code for the native macOS desktop app:
  - `main.swift` & `App/AppDelegate.swift`: Application bootstrap, window management, and native menu shortcuts.
  - `Models/`: Domain structs (`EWRModels.swift`) and localization dictionary (`Localization.swift`).
  - `Services/`: Path resolver (`EWRPaths.swift`), subprocess NDJSON runner (`EWRProcessRunner.swift`), and database/backup loader (`DatabaseService.swift`).
  - `ViewModels/`: `@MainActor` state container (`EWRViewModel.swift`).
  - `Views/`: `MainContentView.swift`, `Components/` (`StatusPillView.swift`, `ConsoleDrawerView.swift`), `Tabs/` (5 feature tabs), and `Sheets/` (Dry-run and Reset confirmation modals).
- `server/`: Modular Node.js HTTP backend:
  - `config.js`: Port, host, and path constants (`BIN_DIR`, `EWR_BIN`, `DB_PATH`, `GUI_DIR`, `BACKUP_DIRS`).
  - `services/`: `ewrRunner.js`, `databaseService.js`, `backupService.js`, `sseService.js`.
  - `routes/apiRouter.js`: REST endpoint dispatcher (`/api/*`).
  - `middleware/staticServer.js`: Static asset responder for `gui/`.
- `gui/`: Modular Vanilla Web Frontend:
  - `index.html` & `style.css`: HTML shell and `@import` CSS entry point.
  - `css/`: `variables.css` (theme tokens), `layout.css`, `components.css`.
  - `js/`: Native ES modules (`main.js`, `api.js`, `state.js`, `i18n.js`, and `ui/` feature modules `dom.js`, `logger.js`, `dashboard.js`, `maintenance.js`, `diagnostics.js`, `backups.js`, `database.js`).
- `bin/`: Prebuilt `bin/ewr` binary, compiled `bin/ewr-gui-macos`, and `bin/database.json`.
- `backups/`: Target and lookup directory for EEPROM backup files.

---

## Development Commands

### macOS Native App (SwiftUI + AppKit)
```bash
npm run build:mac                                 # Compile native/**/*.swift -> bin/ewr-gui-macos & .app bundle
npm run app                                       # Launch compiled bin/ewr-gui-macos directly
```

### Web Backend & UI Server
```bash
npm start                                         # Run server via Node.js on http://127.0.0.1:3827
node server.js                                    # Run directly with Node.js (zero npm dependencies)
bun server.js                                     # Alternative runtime with Bun
PORT=8080 node server.js                          # Run on custom port
```

### System Launchers
```bash
./start.sh                                        # Launches native macOS app directly on Darwin, or web server fallback
./start.sh --web                                  # Forces Node/Bun server startup and opens browser
start.bat                                         # Windows launcher script
```

---

## Code Conventions & Common Patterns

### Process Execution & Protocol
- Every execution of `bin/ewr` in `native/Services/EWRProcessRunner.swift` and `server/services/ewrRunner.js` passes `NO_COLOR=1` and `--json`.
- Standard output is newline-delimited JSON (NDJSON):
  - `{ "type": "hello", ... }`: Tool initialization metadata.
  - `{ "type": "event", ... }`: Real-time stage/progress updates.
  - `{ "type": "result", "ok": true|false, ... }`: Final execution outcome.
- Destructive actions (`--reset`, `--maintenance`, `--restore`) require `--yes` or `--force-yes` when run with `--json`.

### Modularity & State Management
- **Native macOS (`native/`)**: Keep business logic and `bin/ewr` orchestration inside `ViewModels/EWRViewModel.swift` and `Services/*`. Views under `Views/Tabs/*` and `Views/Sheets/*` observe `@ObservedObject var vm: EWRViewModel` (avoiding macro-dependent `@State` where possible so standalone `swiftc` builds without external macro plugins).
- **Web Backend (`server/`)**: Keep HTTP route parsing in `server/routes/apiRouter.js` and side-effecting logic in `server/services/*`. Zero external npm packages (`package.json` has no `dependencies`).
- **Web Frontend (`gui/js/`)**: Use native browser ES Modules (`import`/`export`). All DOM queries belong in `gui/js/ui/dom.js`; all `fetch` calls belong in `gui/js/api.js`.

### Localization & Copy (I18N)
- **Indonesian (`id`)** is the primary default language; **English (`en`)** is secondary.
- All new user-facing GUI text MUST be added to both `id` and `en` in `gui/js/i18n.js` (`I18N`) and `native/Models/Localization.swift` (`L10n`).

### Hardware Safety Patterns
- **Backups First**: An EEPROM backup MUST be generated before initiating any counter reset or EEPROM restore.
- **Dry Run Verification**: Use `/api/dry-run` or `--dry-run` to inspect planned register writes before executing physical writes.
- **Mandatory Power Cycle**: Printers MUST be turned off and back on after a successful reset to re-read cleared EEPROM registers.

---

## Important Files

- `native/main.swift` & `native/App/AppDelegate.swift`: Native macOS app entry and window controller.
- `native/ViewModels/EWRViewModel.swift`: Central ViewModel for the native macOS app.
- `server.js` & `server/routes/apiRouter.js`: Web server entry point and REST API router.
- `gui/index.html` & `gui/js/main.js`: Web frontend HTML shell and ES module bootstrap.
- `bin/ewr` & `bin/database.json`: Upstream printer communication binary and ~1450-model database.
- `package.json`: Project metadata and build scripts (`build:mac`, `start`, `app`).

---

## Runtime/Tooling Preferences

- **Swift Compiler**: `swiftc` with `-framework Cocoa -framework SwiftUI` for compiling the native macOS application.
- **Node.js / Bun**: Node.js (>= 16) or Bun for running `server.js` (zero external npm packages).

---

## Testing & QA

- **Simulation (Dry Run)**:
  - Verify reset logic and parameter parsing using `/api/dry-run` or `bin/ewr --dry-run` before testing on hardware.
- **Smoke Testing Flow**:
  1. Build native macOS app: `npm run build:mac`
  2. Start web server: `node server.js`
  3. Verify API & spec resolution: `curl -s "http://127.0.0.1:3827/api/models?q=L3110&limit=1"`
  4. Verify ES module & CSS delivery: `curl -I http://127.0.0.1:3827/js/main.js`
