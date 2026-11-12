import Foundation

enum EWRProcessRunner {
    static func execute(
        binaryPath: String,
        repoRoot: String,
        args: [String],
        stage: String,
        onEvent: (@MainActor ([String: Any]) -> Void)? = nil
    ) async -> EWRRunOutput {
        guard FileManager.default.isExecutableFile(atPath: binaryPath) else {
            let msg = "Binary ewr tidak ditemukan di \(binaryPath)"
            return EWRRunOutput(
                exitCode: -1,
                ok: false,
                errorCode: "binary_missing",
                errorMessage: msg,
                data: [:],
                events: [],
                rawStderr: msg
            )
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: binaryPath)
                proc.arguments = args + ["--json"]
                proc.currentDirectoryURL = URL(fileURLWithPath: repoRoot)

                var env = ProcessInfo.processInfo.environment
                env["NO_COLOR"] = "1"
                proc.environment = env

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                proc.standardOutput = stdoutPipe
                proc.standardError = stderrPipe

                let lock = NSLock()
                var lineBuffer = ""
                var resultObj: [String: Any]? = nil
                var eventsList: [[String: Any]] = []
                var stderrData = Data()

                let parseLine: (String) -> Void = { line in
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty,
                          let data = trimmed.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let type = json["type"] as? String else {
                        return
                    }
                    if type == "event" {
                        lock.lock()
                        eventsList.append(json)
                        lock.unlock()
                        Task { @MainActor in
                            onEvent?(json)
                        }
                    } else if type == "result" {
                        lock.lock()
                        resultObj = json
                        lock.unlock()
                    }
                }

                stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                    let chunk = handle.availableData
                    guard !chunk.isEmpty, let str = String(data: chunk, encoding: .utf8) else { return }
                    lock.lock()
                    lineBuffer += str
                    var lines = lineBuffer.components(separatedBy: "\n")
                    lineBuffer = lines.removeLast()
                    lock.unlock()
                    for line in lines {
                        parseLine(line)
                    }
                }

                stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                    let chunk = handle.availableData
                    guard !chunk.isEmpty else { return }
                    lock.lock()
                    stderrData.append(chunk)
                    lock.unlock()
                }

                do {
                    try proc.run()
                    proc.waitUntilExit()
                } catch {
                    stdoutPipe.fileHandleForReading.readabilityHandler = nil
                    stderrPipe.fileHandleForReading.readabilityHandler = nil
                    let errMsg = error.localizedDescription
                    continuation.resume(returning: EWRRunOutput(
                        exitCode: -1,
                        ok: false,
                        errorCode: "spawn_failed",
                        errorMessage: errMsg,
                        data: [:],
                        events: [],
                        rawStderr: errMsg
                    ))
                    return
                }

                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                let remainingOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                if !remainingOut.isEmpty, let str = String(data: remainingOut, encoding: .utf8) {
                    lock.lock()
                    lineBuffer += str
                    lock.unlock()
                }
                for line in lineBuffer.components(separatedBy: "\n") {
                    parseLine(line)
                }

                let remainingErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                if !remainingErr.isEmpty {
                    stderrData.append(remainingErr)
                }

                let rawStderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let ok = (resultObj?["ok"] as? Bool) ?? false
                let errorCode = resultObj?["error_code"] as? String
                let errorMsg = (resultObj?["error"] as? String) ?? (proc.terminationStatus != 0 && !rawStderr.isEmpty ? rawStderr : nil)
                let resultData = (resultObj?["data"] as? [String: Any]) ?? [:]

                continuation.resume(returning: EWRRunOutput(
                    exitCode: proc.terminationStatus,
                    ok: ok,
                    errorCode: errorCode,
                    errorMessage: errorMsg,
                    data: resultData,
                    events: eventsList,
                    rawStderr: rawStderr
                ))
            }
        }
    }
}
