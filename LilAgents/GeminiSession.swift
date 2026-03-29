import Foundation

class GeminiSession: AgentSession {
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var lineBuffer = ""
    private var currentResponseText = ""
    private(set) var isRunning = false
    private(set) var isBusy = false
    private var isFirstTurn = true
    private static var binaryPath: String?

    var onText: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onToolUse: ((String, [String: Any]) -> Void)?
    var onToolResult: ((String, Bool) -> Void)?
    var onSessionReady: (() -> Void)?
    var onTurnComplete: (() -> Void)?
    var onProcessExit: (() -> Void)?

    var history: [AgentMessage] = []

    // MARK: - Process Lifecycle

    func start() {
        if Self.binaryPath != nil {
            isRunning = true
            onSessionReady?()
            return
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        ShellEnvironment.findBinary(name: "gemini", fallbackPaths: [
            "\(home)/.local/bin/gemini",
            "\(home)/.npm-global/bin/gemini",
            "/usr/local/bin/gemini",
            "/opt/homebrew/bin/gemini"
        ]) { [weak self] path in
            guard let self = self, let binaryPath = path else {
                let msg = "Gemini CLI not found.\n\n\(AgentProvider.gemini.installInstructions)"
                self?.onError?(msg)
                self?.history.append(AgentMessage(role: .error, text: msg))
                return
            }
            Self.binaryPath = binaryPath
            self.isRunning = true
            self.onSessionReady?()
        }
    }

    func send(message: String) {
        guard isRunning, let binaryPath = Self.binaryPath else { return }
        isBusy = true
        currentResponseText = ""
        lineBuffer = ""
        history.append(AgentMessage(role: .user, text: message))

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)

        var args: [String] = []
        if !isFirstTurn {
            args.append("--continue")
        }
        args.append(contentsOf: [
            "-p", message,
            "--output-format", "stream-json",
            "--yolo"
        ])
        proc.arguments = args

        proc.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        proc.environment = ShellEnvironment.processEnvironment(extraPaths: [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".npm-global/bin").path,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin").path
        ])

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.process = nil

                // Flush remaining buffer
                if !self.lineBuffer.isEmpty {
                    self.parseLine(self.lineBuffer)
                    self.lineBuffer = ""
                }

                if self.isBusy {
                    self.isBusy = false
                    if !self.currentResponseText.isEmpty {
                        self.history.append(AgentMessage(role: .assistant, text: self.currentResponseText))
                    }
                    self.currentResponseText = ""
                    self.onTurnComplete?()
                }
            }
        }

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.processOutput(text)
                }
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.onError?(text)
                }
            }
        }

        do {
            try proc.run()
            process = proc
            outputPipe = outPipe
            errorPipe = errPipe
            isFirstTurn = false
        } catch {
            isBusy = false
            let msg = "Failed to launch Gemini CLI.\n\n\(AgentProvider.gemini.installInstructions)\n\nError: \(error.localizedDescription)"
            onError?(msg)
            history.append(AgentMessage(role: .error, text: msg))
        }
    }

    func terminate() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminate()
        process = nil
        isRunning = false
        isBusy = false
    }

    // MARK: - NDJSON Parsing

    private func processOutput(_ text: String) {
        lineBuffer += text
        while let newlineRange = lineBuffer.range(of: "\n") {
            let line = String(lineBuffer[lineBuffer.startIndex..<newlineRange.lowerBound])
            lineBuffer = String(lineBuffer[newlineRange.upperBound...])
            if !line.isEmpty {
                parseLine(line)
            }
        }
    }

    private func parseLine(_ line: String) {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let type = json["type"] as? String ?? ""

        switch type {
        case "system":
            let subtype = json["subtype"] as? String ?? ""
            if subtype == "init" {
                // Session initialized for this turn
            }

        case "assistant":
            if let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content {
                    let blockType = block["type"] as? String ?? ""
                    if blockType == "text", let text = block["text"] as? String {
                        currentResponseText += text
                        onText?(text)
                    } else if blockType == "tool_use" {
                        let toolName = block["name"] as? String ?? "Tool"
                        let input = block["input"] as? [String: Any] ?? [:]
                        let summary = formatToolSummary(toolName: toolName, input: input)
                        history.append(AgentMessage(role: .toolUse, text: "\(toolName): \(summary)"))
                        onToolUse?(toolName, input)
                    }
                }
            }

        case "user":
            if let message = json["message"] as? [String: Any],
               let content = message["content"] as? [[String: Any]] {
                for block in content {
                    if block["type"] as? String == "tool_result" {
                        let isError = block["is_error"] as? Bool ?? false
                        var summary = ""
                        if let resultInfo = json["tool_use_result"] as? [String: Any] {
                            if let text = resultInfo["type"] as? String, text == "text" {
                                if let file = resultInfo["file"] as? [String: Any],
                                   let path = file["filePath"] as? String {
                                    let lines = file["totalLines"] as? Int ?? 0
                                    summary = "\(path) (\(lines) lines)"
                                }
                            }
                        } else if let resultStr = json["tool_use_result"] as? String {
                            summary = String(resultStr.prefix(80))
                        }
                        if summary.isEmpty {
                            if let contentStr = block["content"] as? String {
                                summary = String(contentStr.prefix(80))
                            }
                        }
                        history.append(AgentMessage(role: .toolResult, text: isError ? "ERROR: \(summary)" : summary))
                        onToolResult?(summary, isError)
                    }
                }
            }

        case "result":
            isBusy = false
            let finalText: String
            if let result = json["result"] as? String, !result.isEmpty {
                finalText = result
            } else if !currentResponseText.isEmpty {
                finalText = currentResponseText
            } else {
                finalText = ""
            }
            if !finalText.isEmpty {
                history.append(AgentMessage(role: .assistant, text: finalText))
            }
            currentResponseText = ""
            onTurnComplete?()

        case "error":
            let msg = json["message"] as? String ?? json["error"] as? String ?? "Unknown Gemini error"
            onError?(msg)
            history.append(AgentMessage(role: .error, text: msg))

        default:
            break
        }
    }

    private func formatToolSummary(toolName: String, input: [String: Any]) -> String {
        switch toolName {
        case "Bash":
            return input["command"] as? String ?? ""
        case "Read":
            return input["file_path"] as? String ?? ""
        case "Edit", "Write":
            return input["file_path"] as? String ?? ""
        case "Glob":
            return input["pattern"] as? String ?? ""
        case "Grep":
            return input["pattern"] as? String ?? ""
        default:
            if let desc = input["description"] as? String { return desc }
            return input.keys.sorted().prefix(3).joined(separator: ", ")
        }
    }
}
