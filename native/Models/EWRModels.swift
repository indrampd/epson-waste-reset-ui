import Cocoa
import SwiftUI

enum NavTab: String, CaseIterable, Identifiable {
    case dashboard
    case maintenance
    case info
    case backup
    case database

    var id: String { rawValue }
}

struct DetectedDevice: Identifiable, Hashable {
    let id: String // "usb:0" or "ip:192.168.1.50"
    let label: String
    let isUsb: Bool
    let interfaceIndex: Int?
    let ipAddress: String?
    let modelMatch: String
    let deviceId: String
}

struct PadCounterItem: Identifiable {
    let id = UUID()
    let kind: String
    let name: String
    let used: Int
    let max: Int
    let percent: Int
}

struct InkLevelItem: Identifiable {
    var id: String { color }
    let color: String
    let hardwareLevel: Int?
    var manualLevel: Int

    var effectiveLevel: Int { hardwareLevel ?? manualLevel }
    var isEcoTankVisual: Bool { hardwareLevel == nil }
}

struct PlannedWriteItem: Identifiable {
    var id: Int { address }
    let address: Int
    let value: Int
}

struct DiagnosticCounterItem: Identifiable {
    let id = UUID()
    let key: String
    let formattedKey: String
    let valueText: String
}

struct FatalErrorItem: Identifiable {
    let id = UUID()
    let slot: String
    let kind: String
    let code: String
}

struct BackupFileItem: Identifiable {
    var id: String { filepath }
    let filename: String
    let filepath: String
    let sizeBytes: Int64
    let created: Date
}

struct PrinterModelEntry: Identifiable {
    var id: String { name }
    let name: String
    let aliases: [String]
    let hasPadGroups: Bool
    let isKeyless: Bool
    let cleaningLevels: [String]
    let hasPowerClean: Bool
    let rkey: String
    let wkey: String
    let searchBlob: String
}

enum LogLevel: String {
    case info
    case success
    case warn
    case error
    case event

    var badgeText: String {
        switch self {
        case .info: return "INFO"
        case .success: return "OK"
        case .warn: return "WARN"
        case .error: return "ERR"
        case .event: return "EVT"
        }
    }

    var color: Color {
        switch self {
        case .info: return .secondary
        case .success: return Color(nsColor: .systemGreen)
        case .warn: return Color(nsColor: .systemOrange)
        case .error: return Color(nsColor: .systemRed)
        case .event: return Color(nsColor: .systemBlue)
        }
    }
}

struct ConsoleLogEntry: Identifiable {
    let id = UUID()
    let timestamp: String
    let message: String
    let level: LogLevel
}

enum StepState {
    case pending
    case active
    case done
    case failed
}

struct EWRRunOutput {
    let exitCode: Int32
    let ok: Bool
    let errorCode: String?
    let errorMessage: String?
    let data: [String: Any]
    let events: [[String: Any]]
    let rawStderr: String
}
