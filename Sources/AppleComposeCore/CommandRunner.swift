import Foundation

public struct CommandRunner {
    public init() {}

    public func run(_ command: ShellCommand) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command.executable] + command.arguments

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw RunnerError.failed(command.description, Int(process.terminationStatus))
        }
    }
}

public enum RunnerError: Error, LocalizedError {
    case failed(String, Int)

    public var errorDescription: String? {
        switch self {
        case .failed(let command, let status):
            return "command failed (\(status)): \(command)"
        }
    }
}
