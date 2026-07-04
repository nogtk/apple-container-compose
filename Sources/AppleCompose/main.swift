import AppleComposeCore
import Foundation

enum CLIError: Error, LocalizedError {
    case usage
    case missingFile(String)
    case unknownCommand(String)

    var errorDescription: String? {
        switch self {
        case .usage:
            return """
            Usage:
              apple-compose up [-f compose.yaml] [--dry-run]
              apple-compose down [-f compose.yaml] [--dry-run]
              apple-compose config [-f compose.yaml]
            """
        case .missingFile(let path):
            return "YAML file not found: \(path)"
        case .unknownCommand(let command):
            return "unknown command: \(command)"
        }
    }
}

struct Options {
    var command: String
    var file: String = "compose.yaml"
    var dryRun = false
}

func parseOptions(_ arguments: [String]) throws -> Options {
    guard let command = arguments.first else {
        throw CLIError.usage
    }

    var options = Options(command: command)
    var index = 1
    while index < arguments.count {
        switch arguments[index] {
        case "-f", "--file":
            guard index + 1 < arguments.count else { throw CLIError.usage }
            options.file = arguments[index + 1]
            index += 2
        case "--dry-run":
            options.dryRun = true
            index += 1
        default:
            throw CLIError.usage
        }
    }

    return options
}

func loadComposeFile(path: String) throws -> ComposeFile {
    guard FileManager.default.fileExists(atPath: path) else {
        throw CLIError.missingFile(path)
    }

    let yaml = try String(contentsOfFile: path, encoding: .utf8)
    return try ComposeParser().parse(yaml)
}

func joinedNames<T>(_ values: [T], _ keyPath: KeyPath<T, String>) -> String {
    values.map { $0[keyPath: keyPath] }.joined(separator: ", ")
}

do {
    let options = try parseOptions(Array(CommandLine.arguments.dropFirst()))
    let file = try loadComposeFile(path: options.file)
    let planner = ComposePlanner()
    let commands: [ShellCommand]

    switch options.command {
    case "up":
        commands = planner.planUp(file)
    case "down":
        commands = planner.planDown(file)
    case "config":
        print("project: \(file.project)")
        print("services: \(joinedNames(file.services, \.name))")
        print("volumes: \(joinedNames(file.volumes, \.name))")
        print("networks: \(joinedNames(file.networks, \.name))")
        exit(0)
    default:
        throw CLIError.unknownCommand(options.command)
    }

    if options.dryRun {
        commands.forEach { print($0.description) }
    } else {
        let runner = CommandRunner()
        for command in commands {
            print(command.description)
            try runner.run(command)
        }
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
