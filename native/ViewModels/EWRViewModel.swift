import Cocoa
import SwiftUI

@MainActor
final class EWRViewModel: ObservableObject {
    let paths = EWRPaths.resolve()

    @Published var lang: AppLang = {
        if let saved = UserDefaults.standard.string(forKey: "ewr_lang"),
           let l = AppLang(rawValue: saved) {
            return l
        }
        return .id
    }()

    @Published var isDarkMode: Bool = {
        if UserDefaults.standard.object(forKey: "ewr_dark_mode") != nil {
            return UserDefaults.standard.bool(forKey: "ewr_dark_mode")
        }
        return true
    }()

    @Published var selectedTab: NavTab = .dashboard

    // Device bar state
    @Published var devices: [DetectedDevice] = []
    @Published var selectedDeviceId: String = ""
    @Published var isDeviceMenuOpen: Bool = false
    @Published var modelOverride: String = ""
    @Published var isScanningDevices: Bool = false
    @Published var isBusy: Bool = false
    @Published var connectionBadgeText: String = "Memindai..."
    @Published var isConnected: Bool = false

    // Alert banner
    @Published var alertMessage: String? = nil
    @Published var alertType: LogLevel = .info

    // Dashboard state
    @Published var printerName: String = "-"
    @Published var printerConn: String = "USB"
    @Published var printerCondition: String = "Normal / Siap"
    @Published var printerStateBadge: String = "SIAP"
    @Published var deviceIdString: String = "-"
    @Published var pads: [PadCounterItem] = [
        PadCounterItem(kind: "main", name: "Main Pad Counter", used: 0, max: 6346, percent: 0),
        PadCounterItem(kind: "platen", name: "Platen Pad Counter", used: 0, max: 3416, percent: 0)
    ]
    @Published var inks: [InkLevelItem] = []

    // Maintenance state
    @Published var cleanLevel: String = "normal"
    @Published var cleanGroup: String = "all"
    @Published var nozzleVariantAlt: Bool = false
    @Published var confirmPowerClean: Bool = false

    // Diagnostics state
    @Published var diagFirmware: String = "-"
    @Published var diagSerial: String = "-"
    @Published var diagCounters: [DiagnosticCounterItem] = []
    @Published var fatalErrors: [FatalErrorItem] = []

    // Backups state
    @Published var backups: [BackupFileItem] = []
    @Published var selectedRestoreItem: BackupFileItem? = nil

    // Database state
    @Published var allModels: [PrinterModelEntry] = []
    @Published var dbSearchQuery: String = ""

    // Dry Run Sheet state
    @Published var showDryRunSheet: Bool = false
    @Published var isDryRunLoading: Bool = false
    @Published var dryRunError: String? = nil
    @Published var dryRunModel: String = "-"
    @Published var dryRunCovers: String = "-"
    @Published var plannedWrites: [PlannedWriteItem] = []

    // Reset Sheet state
    @Published var showResetSheet: Bool = false
    @Published var confirmPowerCycle: Bool = false
    @Published var forceYesReset: Bool = false
    @Published var isResetInProgress: Bool = false
    @Published var step1State: StepState = .pending
    @Published var step2State: StepState = .pending
    @Published var step3State: StepState = .pending
    @Published var step4State: StepState = .pending
    @Published var resetFinishedOk: Bool? = nil
    @Published var resetResultMessage: String = ""

    // Console Drawer state
    @Published var logs: [ConsoleLogEntry] = []
    @Published var isConsoleExpanded: Bool = true

    var t: L10n { L10n(lang: lang) }

    var filteredModels: [PrinterModelEntry] {
        let q = dbSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return Array(allModels.prefix(150))
        }
        return Array(allModels.filter { $0.searchBlob.contains(q) }.prefix(150))
    }

    var totalMatchingModelsCount: Int {
        let q = dbSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return allModels.count }
        return allModels.filter { $0.searchBlob.contains(q) }.count
    }

    init() {
        applyTheme()
        log(lang == .id
            ? "Aplikasi Native macOS siap. Binary EWR: \(paths.ewrBinary)"
            : "Native macOS App ready. EWR binary: \(paths.ewrBinary)",
            level: .info)
        loadDatabaseAsync()
        loadBackups()
        Task {
            await scanDevices(autoReadStatus: true)
        }
    }

    func setLanguage(_ newLang: AppLang) {
        lang = newLang
        UserDefaults.standard.set(newLang.rawValue, forKey: "ewr_lang")
        if !isConnected && !isScanningDevices {
            connectionBadgeText = t.notConnected
        }
    }

    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "ewr_dark_mode")
        applyTheme()
    }

    func applyTheme() {
        NSApp.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
    }

    func log(_ message: String, level: LogLevel = .info) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let ts = formatter.string(from: Date())
        logs.append(ConsoleLogEntry(timestamp: ts, message: message, level: level))
    }

    func showAlert(_ message: String, level: LogLevel = .info) {
        alertMessage = message
        alertType = level
    }

    func hideAlert() {
        alertMessage = nil
    }

    func buildTargetArgs() -> [String] {
        var args: [String] = []
        if let dev = devices.first(where: { $0.id == selectedDeviceId }) {
            if let idx = dev.interfaceIndex {
                args.append(contentsOf: ["--interface", String(idx)])
            } else if let ip = dev.ipAddress, !ip.isEmpty {
                args.append(contentsOf: ["--ip", ip])
            }
        }
        let trimmedModel = modelOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedModel.isEmpty {
            args.append(contentsOf: ["--model", trimmedModel])
        }
        return args
    }

    func handleDeviceSelectionChange() {
        guard let dev = devices.first(where: { $0.id == selectedDeviceId }) else { return }
        if !dev.modelMatch.isEmpty && modelOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            modelOverride = dev.modelMatch
        }
        printerConn = dev.isUsb ? "USB (Direct)" : "Network (LAN/Wi-Fi)"
        if !dev.deviceId.isEmpty {
            deviceIdString = dev.deviceId
        }
        isConnected = true
        connectionBadgeText = dev.label
    }

    func getManualTankLevel(for color: String) -> Int {
        let key = "ewr_tank_\(color.lowercased())"
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.integer(forKey: key)
        }
        return 80
    }

    func setManualTankLevel(for color: String, level: Int) {
        let clamped = min(max(level, 10), 100)
        let key = "ewr_tank_\(color.lowercased())"
        UserDefaults.standard.set(clamped, forKey: key)
        if let idx = inks.firstIndex(where: { $0.color == color }) {
            inks[idx].manualLevel = clamped
        }
    }

    func executeEwr(args: [String], stage: String, onEvent: (@MainActor ([String: Any]) -> Void)? = nil) async -> EWRRunOutput {
        await EWRProcessRunner.execute(
            binaryPath: paths.ewrBinary,
            repoRoot: paths.repoRoot,
            args: args,
            stage: stage
        ) { [weak self] json in
            guard let self = self else { return }
            let code = json["code"] as? String ?? stage
            let msg = json["message"] as? String ?? ""
            if !msg.isEmpty {
                self.log("[\(code)] \(msg)", level: .event)
            }
            onEvent?(json)
        }
    }

    func scanDevices(autoReadStatus: Bool = false) async {
        isScanningDevices = true
        connectionBadgeText = t.scanningDevices
        log("Scanning USB interfaces and network printers (ewr --list)...", level: .info)

        let out = await executeEwr(args: ["--list"], stage: "list")
        isScanningDevices = false

        var found: [DetectedDevice] = []
        if let usbList = out.data["interfaces"] as? [[String: Any]] {
            for item in usbList {
                let idx = item["index"] as? Int ?? 0
                let ifNum = item["interface_number"] as? Int ?? idx
                let modelMatch = item["model_match"] as? String ?? ""
                let devId = item["device_id"] as? String ?? ""
                let parsedName = !modelMatch.isEmpty ? modelMatch : parseDeviceIdModel(devId)
                let label = "USB: \(parsedName) [if_\(ifNum)]"
                found.append(DetectedDevice(
                    id: "usb:\(idx)",
                    label: label,
                    isUsb: true,
                    interfaceIndex: idx,
                    ipAddress: nil,
                    modelMatch: modelMatch,
                    deviceId: devId
                ))
            }
        }

        if let netList = out.data["network_printers"] as? [[String: Any]] {
            for item in netList {
                guard let addr = item["address"] as? String else { continue }
                let reported = item["reported_model"] as? String ?? ""
                let modelMatch = item["model_match"] as? String ?? ""
                let displayModel = !reported.isEmpty ? reported : (!modelMatch.isEmpty ? modelMatch : "Epson")
                let label = "LAN: \(displayModel) (\(addr))"
                found.append(DetectedDevice(
                    id: "ip:\(addr)",
                    label: label,
                    isUsb: false,
                    interfaceIndex: nil,
                    ipAddress: addr,
                    modelMatch: modelMatch,
                    deviceId: ""
                ))
            }
        }

        devices = found

        if let first = found.first {
            selectedDeviceId = first.id
            handleDeviceSelectionChange()
            log("Found \(found.count) printer connection(s).", level: .success)
            if autoReadStatus {
                await readStatus()
            }
        } else {
            selectedDeviceId = ""
            isConnected = false
            connectionBadgeText = t.notConnected
            if let err = out.errorMessage {
                log("Scan notice: \(err)", level: .warn)
            }
        }
    }

    private func parseDeviceIdModel(_ devId: String) -> String {
        guard let range = devId.range(of: "MDL:") else { return "Epson Printer" }
        let sub = devId[range.upperBound...]
        if let semi = sub.firstIndex(of: ";") {
            return String(sub[..<semi])
        }
        return String(sub)
    }

    func readStatus() async {
        hideAlert()
        isBusy = true
        let targetArgs = buildTargetArgs()
        log("Reading waste ink counter status...", level: .info)

        let out = await executeEwr(args: ["--status", "--no-update"] + targetArgs, stage: "status")
        isBusy = false

        guard out.ok else {
            let err = out.errorMessage ?? out.errorCode ?? (lang == .id ? "Gagal membaca status printer." : "Failed to read printer status.")
            log("Read status failed: \(err)", level: .error)
            showAlert(err, level: .error)
            return
        }

        applyStatusData(out.data)
        log("Counter status updated.", level: .success)
    }

    private func applyStatusData(_ data: [String: Any]) {
        let detected = (data["detected_model"] as? String) ?? (data["model"] as? String) ?? "-"
        printerName = detected
        if let mdl = data["model"] as? String, modelOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            modelOverride = mdl
        }

        if let printerDict = data["printer"] as? [String: Any] {
            let st = (printerDict["state"] as? String) ?? "READY"
            printerStateBadge = st
            if let err = printerDict["error"] as? String, !err.isEmpty {
                printerCondition = "Error: \(err)"
            } else {
                printerCondition = lang == .id ? "Normal / Siap" : "Normal / Ready"
            }

            if let rawInks = printerDict["inks"] as? [[String: Any]] {
                var parsedInks: [InkLevelItem] = []
                for ink in rawInks {
                    let color = (ink["color"] as? String) ?? "Ink"
                    let hwLevel = ink["level"] as? Int
                    let savedManual = getManualTankLevel(for: color)
                    parsedInks.append(InkLevelItem(color: color, hardwareLevel: hwLevel, manualLevel: savedManual))
                }
                inks = parsedInks
            } else {
                inks = []
            }
        }

        if let rawPads = data["pads"] as? [[String: Any]], !rawPads.isEmpty {
            var parsedPads: [PadCounterItem] = []
            for p in rawPads {
                let kind = (p["kind"] as? String) ?? "pad"
                let name = (p["name"] as? String) ?? (p["desc"] as? String) ?? (kind == "main" ? t.counterMain : t.counterPlaten)
                let used = (p["used"] as? Int) ?? 0
                let maxVal = max((p["max"] as? Int) ?? 6346, 1)
                let pct: Int
                if let pNum = p["percent"] as? Double {
                    pct = Int(pNum.rounded())
                } else if let pInt = p["percent"] as? Int {
                    pct = pInt
                } else {
                    pct = Int((Double(used) / Double(maxVal) * 100.0).rounded())
                }
                parsedPads.append(PadCounterItem(kind: kind, name: name, used: used, max: maxVal, percent: pct))
            }
            pads = parsedPads
        }
    }

    func openAndRunDryRun() async {
        showDryRunSheet = true
        isDryRunLoading = true
        dryRunError = nil
        plannedWrites = []

        let targetArgs = buildTargetArgs()
        log("Running EEPROM reset simulation (--dry-run)...", level: .info)

        let out = await executeEwr(args: ["--dry-run", "--no-update"] + targetArgs, stage: "dry-run")
        isDryRunLoading = false

        guard out.ok else {
            let err = out.errorMessage ?? out.errorCode ?? "Dry-run failed"
            dryRunError = err
            log("Dry-run failed: \(err)", level: .error)
            return
        }

        dryRunModel = (out.data["model"] as? String) ?? (modelOverride.isEmpty ? "Auto" : modelOverride)
        if let covers = out.data["reset_covers"] as? [[String: Any]], !covers.isEmpty {
            dryRunCovers = covers.compactMap { c in
                let n = c["name"] as? String ?? "Pad"
                let k = c["kind"] as? String ?? ""
                return k.isEmpty ? n : "\(n) (\(k))"
            }.joined(separator: ", ")
        } else {
            dryRunCovers = lang == .id ? "Semua Bantalan Reset" : "All Reset Pads"
        }

        if let writes = out.data["planned_writes"] as? [[String: Any]] {
            plannedWrites = writes.compactMap { w in
                guard let addr = w["address"] as? Int, let val = w["value"] as? Int else { return nil }
                return PlannedWriteItem(address: addr, value: val)
            }
        }
        log("Simulation generated \(plannedWrites.count) planned EEPROM register write(s).", level: .success)
    }

    func prepareResetSheet() {
        confirmPowerCycle = false
        forceYesReset = false
        isResetInProgress = false
        resetFinishedOk = nil
        resetResultMessage = ""
        step1State = .pending
        step2State = .pending
        step3State = .pending
        step4State = .pending
        showResetSheet = true
    }

    func executeReset() async {
        isResetInProgress = true
        resetFinishedOk = nil
        step1State = .active
        step2State = .pending
        step3State = .pending
        step4State = .pending

        let targetArgs = buildTargetArgs()
        let confirmFlag = forceYesReset ? "--force-yes" : "--yes"
        log("Executing EEPROM Waste Ink Pad Reset (\(confirmFlag))...", level: .warn)

        let out = await executeEwr(args: [confirmFlag, "--no-update"] + targetArgs, stage: "reset") { [weak self] ev in
            guard let self = self else { return }
            let code = (ev["code"] as? String ?? "").lowercased()
            if code.contains("backup") {
                self.step1State = .done
                self.step2State = .active
            } else if code.contains("write") || code.contains("reset") {
                self.step1State = .done
                self.step2State = .done
                self.step3State = .active
            } else if code.contains("verify") || code.contains("read") {
                self.step1State = .done
                self.step2State = .done
                self.step3State = .done
                self.step4State = .active
            }
        }

        if out.ok {
            step1State = .done
            step2State = .done
            step3State = .done
            step4State = .done
            resetFinishedOk = true
            resetResultMessage = lang == .id
                ? "RESET BERHASIL! Register EEPROM telah di-reset ke 0% dan diverifikasi. WAJIB: Matikan printer dengan tombol Power fisik lalu nyalakan kembali."
                : "RESET SUCCESSFUL! EEPROM registers have been reset to 0% and verified. REQUIRED: Turn the printer off and back on using the physical Power button."
            log("EEPROM reset completed and verified.", level: .success)
            loadBackups()
            await readStatus()
        } else {
            if step1State == .active { step1State = .failed }
            else if step2State == .active { step2State = .failed }
            else if step3State == .active { step3State = .failed }
            else { step4State = .failed }
            resetFinishedOk = false
            let err = out.errorMessage ?? out.errorCode ?? "Unknown reset error"
            resetResultMessage = err
            log("Reset failed: \(err)", level: .error)
        }
    }

    func runMaintenance(action: String) async {
        hideAlert()
        isBusy = true
        var args = ["--no-update"]
        switch action {
        case "nozzle-check":
            args.append("--nozzle-check")
            if nozzleVariantAlt { args.append("alt") }
        case "head-clean":
            args.append("--head-clean")
            args.append(cleanLevel)
            if cleanGroup != "all" {
                args.append(contentsOf: ["--clean-group", cleanGroup])
            }
        case "power-clean":
            args.append("--power-clean")
        default:
            break
        }
        args.append("--yes")
        args.append(contentsOf: buildTargetArgs())

        log("Starting maintenance command: \(action)...", level: .info)
        showAlert(lang == .id ? "Menjalankan \(action)... Harap tunggu." : "Running \(action)... Please wait.", level: .info)

        let out = await executeEwr(args: args, stage: "maintenance")
        isBusy = false

        if out.ok {
            log("Maintenance \(action) completed.", level: .success)
            showAlert(lang == .id ? "Perintah \(action) berhasil dikirim ke printer." : "Command \(action) sent to printer.", level: .success)
        } else {
            let err = out.errorMessage ?? out.errorCode ?? "Maintenance command failed"
            log("Maintenance error: \(err)", level: .error)
            showAlert(err, level: .error)
        }
    }

    func readHardwareInfo() async {
        hideAlert()
        isBusy = true
        let targetArgs = buildTargetArgs()
        log("Reading hardware diagnostics (ewr --info)...", level: .info)

        let out = await executeEwr(args: ["--info", "--no-update"] + targetArgs, stage: "info")
        isBusy = false

        guard out.ok else {
            let err = out.errorMessage ?? out.errorCode ?? (lang == .id ? "Gagal membaca informasi diagnostik." : "Failed to read diagnostic info.")
            log("Read info failed: \(err)", level: .error)
            showAlert(err, level: .error)
            return
        }

        diagFirmware = (out.data["firmware"] as? String) ?? "-"
        diagSerial = (out.data["serial"] as? String) ?? "-"

        if let rawCounters = out.data["counters"] as? [[String: Any]] {
            diagCounters = rawCounters.map { c in
                let key = (c["key"] as? String) ?? "parameter"
                let formatted = key.replacingOccurrences(of: "_", with: " ").capitalized
                let valStr: String
                if let vInt = c["value"] as? Int {
                    valStr = NumberFormatter.localizedString(from: NSNumber(value: vInt), number: .decimal)
                } else if let vStr = c["value"] as? String {
                    valStr = vStr
                } else {
                    valStr = "-"
                }
                return DiagnosticCounterItem(key: key, formattedKey: formatted, valueText: valStr)
            }
        } else {
            diagCounters = []
        }

        if let rawFatal = out.data["fatal_errors"] as? [[String: Any]] {
            fatalErrors = rawFatal.map { f in
                let slotVal = (f["slot"] as? Int).map { "Slot \($0)" } ?? "-"
                let kindVal = (f["kind"] as? String) ?? "-"
                let codeVal: String
                if let cStr = f["code"] as? String {
                    codeVal = cStr
                } else if let cInt = f["code"] as? Int {
                    codeVal = String(format: "0x%02X (%d)", cInt, cInt)
                } else {
                    codeVal = "-"
                }
                return FatalErrorItem(slot: slotVal, kind: kindVal, code: codeVal)
            }
        } else {
            fatalErrors = []
        }

        log("Hardware diagnostic info loaded (\(diagCounters.count) counters).", level: .success)
    }

    func loadBackups() {
        backups = DatabaseService.scanBackups(in: paths.backupDirs)
    }

    func dumpEepromBackup() async {
        hideAlert()
        isBusy = true
        let targetArgs = buildTargetArgs()
        log("Dumping EEPROM backup (ewr --dump)...", level: .info)

        let out = await executeEwr(args: ["--dump", "--no-update"] + targetArgs, stage: "dump")
        isBusy = false

        if out.ok {
            loadBackups()
            let msg = lang == .id ? "Backup EEPROM berhasil disimpan." : "EEPROM backup saved successfully."
            log(msg, level: .success)
            showAlert(msg, level: .success)
        } else {
            let err = out.errorMessage ?? out.errorCode ?? "EEPROM dump failed"
            log("Dump failed: \(err)", level: .error)
            showAlert(err, level: .error)
        }
    }

    func restoreBackup(_ item: BackupFileItem, dryRun: Bool) async {
        hideAlert()
        isBusy = true
        var args = ["--restore", item.filepath, "--no-update"]
        if dryRun {
            args.append("--dry-run")
        } else {
            args.append("--yes")
        }
        args.append(contentsOf: buildTargetArgs())

        log("\(dryRun ? "Simulating" : "Executing") EEPROM restore from \(item.filename)...", level: .warn)
        let out = await executeEwr(args: args, stage: "restore")
        isBusy = false

        if out.ok {
            let msg = dryRun
                ? (lang == .id ? "Simulasi restore valid untuk \(item.filename)." : "Restore dry-run succeeded for \(item.filename).")
                : (lang == .id ? "Restore selesai! Silakan matikan dan nyalakan ulang printer." : "Restore completed! Please power cycle the printer.")
            log(msg, level: .success)
            showAlert(msg, level: .success)
            if !dryRun {
                await readStatus()
            }
        } else {
            let err = out.errorMessage ?? out.errorCode ?? "Restore failed"
            log("Restore failed: \(err)", level: .error)
            showAlert(err, level: .error)
        }
    }

    func revealBackupsInFinder() {
        let primaryDir = paths.backupDirs.first ?? paths.repoRoot
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: primaryDir)
    }

    private func loadDatabaseAsync() {
        let dbPath = paths.databasePath
        DispatchQueue.global(qos: .userInitiated).async {
            let entries = DatabaseService.loadModels(from: dbPath)
            Task { @MainActor in
                self.allModels = entries
            }
        }
    }

    func selectModelFromDatabase(_ modelName: String) {
        modelOverride = modelName
        selectedTab = .dashboard
        showAlert(lang == .id ? "Model \"\(modelName)\" dipilih." : "Model \"\(modelName)\" selected.", level: .info)
    }
}
