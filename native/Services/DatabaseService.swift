import Foundation

enum DatabaseService {
    static func loadModels(from dbPath: String) -> [PrinterModelEntry] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let specs = (root["specs"] as? [String: [String: Any]]) ?? [:]
        let modelsObj = (root["models"] as? [String: [String: Any]]) ?? [:]
        let keylessObj = (root["keyless_models"] as? [String: [String: Any]]) ?? [:]

        var entries: [PrinterModelEntry] = []
        entries.reserveCapacity(modelsObj.count + keylessObj.count)

        let parseKeyString: (Any?) -> String = { val in
            if let s = val as? String { return s }
            if let i = val as? Int { return String(i) }
            return "-"
        }

        for (name, rawInfo) in modelsObj {
            var merged = rawInfo
            if let specName = rawInfo["spec"] as? String, let specDict = specs[specName] {
                for (k, v) in specDict where merged[k] == nil {
                    merged[k] = v
                }
            }

            let aliases = (merged["aliases"] as? [String]) ?? []
            let padGroups = (merged["pad_groups"] as? [Any]) ?? []
            let cleaning = merged["cleaning"] as? [String: Any]
            let cleanMap = cleaning?["clean"] as? [String: Any]
            let cleanLevels = cleanMap.map { Array($0.keys).sorted() } ?? []
            let hasPower = cleaning?["charge"] != nil
            let rkey = parseKeyString(merged["rkey"])
            let wkey = parseKeyString(merged["wkey"])
            let blob = ([name] + aliases).joined(separator: " ").lowercased()

            entries.append(PrinterModelEntry(
                name: name,
                aliases: aliases,
                hasPadGroups: !padGroups.isEmpty,
                isKeyless: false,
                cleaningLevels: cleanLevels,
                hasPowerClean: hasPower,
                rkey: rkey,
                wkey: wkey,
                searchBlob: blob
            ))
        }

        for (name, rawInfo) in keylessObj where modelsObj[name] == nil {
            let aliases = (rawInfo["aliases"] as? [String]) ?? []
            let padGroups = (rawInfo["pad_groups"] as? [Any]) ?? []
            let blob = ([name] + aliases).joined(separator: " ").lowercased()

            entries.append(PrinterModelEntry(
                name: name,
                aliases: aliases,
                hasPadGroups: !padGroups.isEmpty,
                isKeyless: true,
                cleaningLevels: [],
                hasPowerClean: false,
                rkey: "Keyless",
                wkey: "Keyless",
                searchBlob: blob
            ))
        }

        entries.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return entries
    }

    static func scanBackups(in backupDirs: [String]) -> [BackupFileItem] {
        let fm = FileManager.default
        var seen = Set<String>()
        var items: [BackupFileItem] = []

        for dir in backupDirs {
            guard let files = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for fname in files where fname.hasSuffix(".json") || fname.hasSuffix(".txt") {
                guard !seen.contains(fname) else { continue }
                let fullPath = (dir as NSString).appendingPathComponent(fname)
                if let attrs = try? fm.attributesOfItem(atPath: fullPath) {
                    let size = (attrs[.size] as? Int64) ?? 0
                    let mtime = (attrs[.modificationDate] as? Date) ?? Date.distantPast
                    seen.insert(fname)
                    items.append(BackupFileItem(filename: fname, filepath: fullPath, sizeBytes: size, created: mtime))
                }
            }
        }

        return items.sorted { $0.created > $1.created }
    }
}
