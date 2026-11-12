import Foundation

enum AppLang: String, CaseIterable {
    case id = "id"
    case en = "en"
}

struct L10n {
    let lang: AppLang

    var subtitle: String { lang == .id ? "Utilitas Pemulihan & Reset Waste Ink Pad Counter" : "Waste Ink Pad Counter Recovery & Reset Utility" }
    var tabDashboard: String { "Dashboard & Reset" }
    var tabMaintenance: String { "Maintenance (Cleaning)" }
    var tabInfo: String { lang == .id ? "Informasi & Diagnostik" : "Information & Diagnostics" }
    var tabBackup: String { "Backup & Restore" }
    var tabDatabase: String { lang == .id ? "Database Printer" : "Printer Database" }

    var lblDevice: String { lang == .id ? "Perangkat Terdeteksi:" : "Detected Device:" }
    var lblModel: String { lang == .id ? "Model Database:" : "Database Model:" }
    var modelPlaceholder: String { lang == .id ? "Otomatis (atau ketik model, misal L3110)" : "Auto (or type model, e.g. L3110)" }
    var btnRefreshDevices: String { lang == .id ? "Pindai Ulang" : "Rescan" }
    var btnReadStatus: String { lang == .id ? "Baca Counter" : "Read Counters" }
    var noPrinterDetected: String { lang == .id ? "Tidak ada printer terdeteksi (USB / LAN)" : "No printer detected (USB / LAN)" }
    var scanningDevices: String { lang == .id ? "Memindai..." : "Scanning..." }
    var notConnected: String { lang == .id ? "Tidak Terhubung" : "Disconnected" }

    var cardPrinterStatus: String { lang == .id ? "Status Printer" : "Printer Status" }
    var lblPrinterName: String { lang == .id ? "Nama Printer:" : "Printer Model:" }
    var lblPrinterConn: String { lang == .id ? "Koneksi:" : "Connection:" }
    var lblPrinterCondition: String { lang == .id ? "Kondisi Hardware:" : "Hardware State:" }
    var lblDeviceId: String { "Device ID:" }

    var cardWasteCounters: String { "Waste Ink Pad Counters" }
    var descWasteCounters: String { lang == .id ? "Kapasitas penampung tinta pembuangan (Waste Ink Pad) pada EEPROM printer." : "Waste ink pad capacity from internal printer EEPROM registers." }
    var btnRefresh: String { lang == .id ? "Perbarui" : "Refresh" }
    var counterMain: String { lang == .id ? "Main Pad Counter (Bantalan Utama)" : "Main Pad Counter" }
    var counterPlaten: String { lang == .id ? "Platen Pad Counter (Bantalan Platen)" : "Platen Pad Counter" }
    var unitPoints: String { lang == .id ? "poin" : "points" }
    var statusSafe: String { lang == .id ? "AMAN" : "SAFE" }
    var statusWarn: String { lang == .id ? "PERINGATAN (>=80%)" : "WARNING (>=80%)" }
    var statusCrit: String { lang == .id ? "PENUH (100%)" : "FULL (100%)" }
    var inkLevelsTitle: String { lang == .id ? "Estimasi Level Tinta Cartridge (Sensor Chip)" : "Cartridge Ink Level Estimates (Chip Sensor)" }
    var inkTankTitle: String { lang == .id ? "Estimasi Level Tinta EcoTank (Kalibrasi Visual Tabung)" : "EcoTank Ink Level Estimates (Visual Tank Calibration)" }
    var inkTankDesc: String { lang == .id ? "Printer EcoTank menggunakan tabung fisik tanpa sensor chip. Klik bar di bawah agar sesuai dengan garis tinta pada tabung printer Anda." : "EcoTank printers use physical tanks without chip sensors. Click the bars below to match your printer's physical ink tank window." }

    var cardActions: String { lang == .id ? "Pusat Tindakan Reset" : "Reset Actions Center" }
    var descActions: String { lang == .id ? "Reset aman dengan auto-backup EEPROM dan verifikasi baca-ulang hardware." : "Safe reset with preflight auto-backup and hardware read-back verification." }
    var btnDryRun: String { lang == .id ? "Simulasi (Dry Run)" : "Simulation (Dry Run)" }
    var btnDoReset: String { "Reset Waste Ink Pad Counter" }
    var safety1Title: String { "Auto Backup" }
    var safety1Desc: String { lang == .id ? "Nilai EEPROM sebelum ditulis akan disimpan otomatis ke folder backups/." : "Current EEPROM values are automatically saved to backups/ before any write." }
    var safety2Title: String { lang == .id ? "Verifikasi Nyata" : "Read-Back Verify" }
    var safety2Desc: String { lang == .id ? "Setelah penulisan selesai, register dibaca ulang untuk memastikan counter benar-benar 0%." : "After writing, registers are read back to verify counters genuinely hold 0%." }

    var cardMaintenanceTitle: String { lang == .id ? "Pemeliharaan Head Printer" : "Print Head Maintenance" }
    var cardMaintenanceDesc: String { lang == .id ? "Jalankan cetak pola nozzle dan pembersihan head langsung ke printer." : "Execute nozzle checks and head cleanings directly on the printer." }
    var maintNozzleTitle: String { lang == .id ? "Nozzle Check (Uji Semprotan)" : "Nozzle Check Pattern" }
    var maintNozzleDesc: String { lang == .id ? "Mencetak pola nozzle untuk memeriksa garis putus atau nozzle tersumbat. Siapkan kertas HVS biasa." : "Prints the nozzle pattern to diagnose missing lines or clogged nozzles. Load plain paper." }
    var btnPrintNozzle: String { lang == .id ? "Cetak Pola Nozzle" : "Print Nozzle Pattern" }
    var maintCleanTitle: String { lang == .id ? "Head Cleaning (Pembersihan Biasa)" : "Head Cleaning" }
    var maintCleanDesc: String { lang == .id ? "Membersihkan nozzle head printer dengan menyedot sedikit tinta ke bantalan pembuangan." : "Cleans printhead nozzles by purging ink into the waste ink pad." }
    var cleanLevelLbl: String { lang == .id ? "Level Pembersihan:" : "Cleaning Level:" }
    var cleanGroupLbl: String { lang == .id ? "Grup Nozzle:" : "Nozzle Group:" }
    var btnRunClean: String { lang == .id ? "Jalankan Head Cleaning" : "Run Head Cleaning" }
    var maintPowerTitle: String { lang == .id ? "Power Cleaning (Pengisian Tinta Kuat)" : "Power Cleaning (Ink Charge)" }
    var maintPowerDesc: String { lang == .id ? "Penyedotan tinta bertenaga tinggi untuk mengatasi nozzle yang tersumbat parah. Membutuhkan volume tinta cukup banyak." : "High-power ink purge for severely clogged nozzles. Consumes significant ink." }
    var btnRunPowerClean: String { lang == .id ? "Jalankan Power Cleaning" : "Run Power Cleaning" }

    var infoTitle: String { lang == .id ? "Diagnostik Hardware & Riwayat Mesin" : "Hardware Diagnostics & History" }
    var infoDesc: String { lang == .id ? "Informasi internal printer yang tercatat di memori EEPROM." : "Internal hardware counters and diagnostic logs stored in EEPROM." }
    var btnReloadInfo: String { lang == .id ? "Muat Ulang Info" : "Reload Info" }
    var statsTitle: String { lang == .id ? "Statistik Penggunaan" : "Usage Statistics" }
    var fatalTitle: String { lang == .id ? "Riwayat Fatal Error Terakhir" : "Recent Fatal Error Codes" }
    var thStatName: String { "Parameter" }
    var thStatVal: String { lang == .id ? "Nilai Tercatat" : "Recorded Value" }
    var emptyStats: String { lang == .id ? "Belum ada parameter terbaca. Hubungkan printer lalu klik 'Muat Ulang Info'." : "No parameters read yet. Connect a printer and click 'Reload Info'." }
    var emptyFatal: String { lang == .id ? "Tidak ada riwayat fatal error terbaca." : "No fatal error history recorded." }

    var backupTitle: String { lang == .id ? "Backup & Restore EEPROM" : "EEPROM Backups & Restore" }
    var backupDesc: String { lang == .id ? "Daftar arsip memori EEPROM yang tersimpan sebelum proses reset. Anda dapat mengembalikan nilai counter kapan saja." : "List of saved EEPROM states created prior to resets. Counters can be restored anytime." }
    var btnReloadBackups: String { lang == .id ? "Muat Ulang Arsip" : "Reload Backups" }
    var btnOpenBackupFolder: String { lang == .id ? "Buka Folder di Finder" : "Reveal in Finder" }
    var btnDumpEeprom: String { lang == .id ? "Buat Backup Sekarang (Dump)" : "Backup EEPROM Now (Dump)" }
    var emptyBackups: String { lang == .id ? "Belum ada file backup (.json / .txt) di direktori backups/." : "No backup files (.json / .txt) found in backups/ directories." }

    var dbTitle: String { lang == .id ? "Database Model Epson" : "Epson Model Database" }
    var dbDesc: String { lang == .id ? "Cari dan periksa parameter reset, read key, dan register EEPROM untuk tipe printer Epson Anda." : "Search specifications, read keys, and EEPROM register addresses for your Epson model." }
    var dbSearchPlaceholder: String { lang == .id ? "Ketik model printer (misal: L3110, L3150, L120, ET-2800, L8050)..." : "Search printer model (e.g. L3110, L3150, L120, ET-2800, L8050)..." }
    var btnSelectModel: String { lang == .id ? "Pilih" : "Select" }

    var consoleTitle: String { lang == .id ? "Aktivitas & Log Trace Real-time" : "Real-time Activity & Trace Log" }
    var btnClear: String { lang == .id ? "Bersihkan" : "Clear" }
    var btnCopy: String { lang == .id ? "Salin" : "Copy" }
    var btnClose: String { lang == .id ? "Tutup" : "Close" }
    var btnOpen: String { lang == .id ? "Buka" : "Open" }

    var dryrunModalTitle: String { lang == .id ? "Simulasi Reset (Dry Run)" : "Reset Simulation (Dry Run)" }
    var dryrunModalDesc: String { lang == .id ? "Berikut adalah rencana penulisan EEPROM yang akan dieksekusi. Pada mode simulasi, tidak ada data yang ditulis ke printer:" : "The following EEPROM writes will be executed. In simulation mode, no data is written to the printer:" }
    var btnProceedReset: String { lang == .id ? "Lanjutkan ke Reset Asli" : "Proceed to Actual Reset" }

    var resetModalTitle: String { lang == .id ? "Konfirmasi Reset Waste Ink Pad" : "Confirm Waste Ink Pad Reset" }
    var resetWarnTitle: String { lang == .id ? "PENTING:" : "IMPORTANT:" }
    var resetWarnText: String { lang == .id ? "Proses ini akan menulis ulang counter waste ink pad pada memori EEPROM printer menjadi 0%. Sistem akan membuat backup otomatis sebelum penulisan. Pastikan kabel USB tidak dicabut selama proses." : "This operation will reset the waste ink pad counter to 0% in EEPROM. An automatic backup is created before writing. Do not unplug the printer during this process." }
    var chkConfirmLabel: String { lang == .id ? "Saya mengerti bahwa setelah reset berhasil, printer wajib dimatikan dan dinyalakan kembali (power cycle)." : "I understand that once the reset completes, I must turn the printer off and back on (power cycle)." }
    var btnCancel: String { lang == .id ? "Batal" : "Cancel" }
    var btnConfirmReset: String { lang == .id ? "Mulai Reset Sekarang" : "Start Reset Now" }
    var resetProgressTitle: String { lang == .id ? "Sedang Menjalankan Reset EEPROM..." : "Executing EEPROM Reset..." }
    var step1: String { lang == .id ? "Membaca status counter printer" : "Reading preflight counter status" }
    var step2: String { lang == .id ? "Menyimpan backup EEPROM ke folder backups/" : "Saving EEPROM backup to backups/ directory" }
    var step3: String { lang == .id ? "Menulis nilai reset ke register EEPROM" : "Writing reset values to EEPROM registers" }
    var step4: String { lang == .id ? "Verifikasi pembacaan ulang register" : "Verifying registers via read-back" }
}
