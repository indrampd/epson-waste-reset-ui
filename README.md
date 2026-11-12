# Epson Waste Reset UI

Aplikasi utilitas desktop dan web untuk membaca dan me-reset Waste Ink Pad Counter, pemeliharaan head (cleaning & nozzle check), serta backup/restore EEPROM pada printer Epson (~1450+ model didukung).

Didukung oleh binary upstream `ewr` (RxNaison/Epson-Waste-Reset).

---

## Fitur Utama

- **Dashboard & Reset**: Pantau kapasitas Main Pad & Platen Pad, simulasi (Dry Run), dan reset dengan auto-backup serta verifikasi baca-ulang register hardware.
- **Maintenance**: Nozzle Check (normal & alt), Head Cleaning (gentle, normal, medium, strong, per-color/black/all), dan Power Cleaning (ink charge).
- **Informasi & Diagnostik**: Baca Serial Number, versi Firmware, statistik total cetak/scan/cleaning, dan riwayat fatal error hardware.
- **Backup & Restore**: Simpan dump EEPROM sewaktu-waktu dan restore status counter dari file backup sebelumnya.
- **Database Printer**: Pencarian instan spesifikasi, read/write keys, dan status reset untuk ~1450+ model Epson.

---

## Mode Penggunaan

### 1. Aplikasi Desktop Native macOS (SwiftUI + AppKit)
Berjalan langsung sebagai aplikasi native macOS tanpa memerlukan WebKit atau server background Node.js:

```bash
# Jalankan aplikasi native langsung
./start.sh
# Atau lewat npm
npm run app

# Kompilasi ulang dari source modular (native/**/*.swift)
npm run build:mac
```

### 2. Antarmuka Web (Cross-Platform Browser)
Dapat diakses lewat browser di `http://127.0.0.1:3827` menggunakan Node.js atau Bun (zero external dependencies):

```bash
# Jalankan web server
./start.sh --web
# Atau secara manual
node server.js
```

---

## Struktur Direktori Modular

```text
├── native/                         # Aplikasi Desktop Native macOS (SwiftUI + AppKit)
│   ├── main.swift                  # Entry point aplikasi
│   ├── App/AppDelegate.swift       # Lifecycle window & menu bar native
│   ├── Models/                     # Domain models & kamus lokalisasi (L10n ID/EN)
│   ├── Services/                   # EWRPaths, EWRProcessRunner (NDJSON), DatabaseService
│   ├── ViewModels/                 # EWRViewModel (@MainActor ObservableObject)
│   └── Views/                      # MainContentView, Components/, Tabs/, Sheets/
│
├── server.js                       # Entry point HTTP & SSE server (Node.js / Bun)
├── server/                         # Modul Backend Web
│   ├── config.js                   # Konfigurasi port & resolusi path direktori
│   ├── services/                   # ewrRunner, databaseService, backupService, sseService
│   ├── routes/apiRouter.js         # Handler endpoint REST API (/api/*)
│   └── middleware/staticServer.js  # Static file server untuk aset gui/
│
├── gui/                            # Frontend Web Modular (Vanilla ES Modules & CSS)
│   ├── index.html                  # Dokumen utama HTML5
│   ├── style.css                   # Entry point stylesheet (@import)
│   ├── css/                        # variables.css, layout.css, components.css
│   └── js/                         # ES Modules: main.js, api.js, state.js, i18n.js, ui/*
│
├── bin/                            # Binary & Database
│   ├── ewr                         # Prebuilt CLI (komunikasi USB D4 & SNMP)
│   ├── ewr-gui-macos               # Hasil kompilasi aplikasi native macOS
│   └── database.json               # Database ~1450 model printer Epson
├── Epson Waste Reset.app/          # Bundle Aplikasi macOS (.app)
└── backups/                        # Direktori penyimpanan otomatis backup EEPROM
```
