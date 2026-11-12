import Foundation

struct EWRPaths {
    let repoRoot: String
    let binDir: String
    let ewrBinary: String
    let databasePath: String
    let backupDirs: [String]

    static func resolve() -> EWRPaths {
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let execPath = CommandLine.arguments.first ?? cwd
        let execDir = (execPath as NSString).deletingLastPathComponent
        let bundlePath = Bundle.main.bundlePath

        let candidateRoots: [String] = [
            cwd,
            execDir,
            (execDir as NSString).deletingLastPathComponent,
            ((execDir as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent,
            (((execDir as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent,
            (bundlePath as NSString).deletingLastPathComponent
        ].map { ($0 as NSString).standardizingPath }

        var chosenRoot = cwd
        for root in candidateRoots {
            let candidateBin = (root as NSString).appendingPathComponent("bin/ewr")
            let candidateDirect = (root as NSString).appendingPathComponent("ewr")
            if fm.isExecutableFile(atPath: candidateBin) {
                chosenRoot = root
                break
            } else if fm.isExecutableFile(atPath: candidateDirect) {
                chosenRoot = (root as NSString).deletingLastPathComponent
                break
            }
        }

        let binDir = (chosenRoot as NSString).appendingPathComponent("bin")
        let ewrBin = (binDir as NSString).appendingPathComponent("ewr")
        let dbPath = (binDir as NSString).appendingPathComponent("database.json")

        let home = fm.homeDirectoryForCurrentUser.path
        let bDirs = [
            (binDir as NSString).appendingPathComponent("backups"),
            (chosenRoot as NSString).appendingPathComponent("backups"),
            (home as NSString).appendingPathComponent("Library/Application Support/EWR/backups"),
            (home as NSString).appendingPathComponent(".local/share/ewr/backups")
        ]

        for d in [bDirs[0], bDirs[1]] {
            if !fm.fileExists(atPath: d) {
                try? fm.createDirectory(atPath: d, withIntermediateDirectories: true)
            }
        }

        return EWRPaths(
            repoRoot: chosenRoot,
            binDir: binDir,
            ewrBinary: ewrBin,
            databasePath: dbPath,
            backupDirs: bDirs
        )
    }
}
