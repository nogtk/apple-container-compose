import Foundation

public enum ComposeParserError: Error, LocalizedError {
    case missingServices
    case missingImage(String)
    case invalidLine(Int, String)

    public var errorDescription: String? {
        switch self {
        case .missingServices:
            return "services が定義されていません"
        case .missingImage(let service):
            return "service '\(service)' に image がありません"
        case .invalidLine(let line, let value):
            return "\(line) 行目の YAML を解釈できません: \(value)"
        }
    }
}

public struct ComposeParser {
    public init() {}

    public func parse(_ yaml: String) throws -> ComposeFile {
        let lines = yaml.split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .compactMap { index, raw -> ParsedLine? in
                let text = String(raw)
                let withoutComment = stripComment(text)
                guard !withoutComment.trimmingCharacters(in: .whitespaces).isEmpty else {
                    return nil
                }
                return ParsedLine(number: index + 1, raw: withoutComment)
            }

        var project = "app"
        var services: [ComposeService] = []
        var volumes: [ComposeVolume] = []
        var networks: [ComposeNetwork] = []
        var section: String?
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let indent = line.indent
            let content = line.content

            if indent == 0 {
                let pair = try keyValue(content, line: line.number)
                switch pair.key {
                case "project", "name":
                    project = pair.value ?? project
                    index += 1
                case "services", "volumes", "networks":
                    section = pair.key
                    index += 1
                default:
                    throw ComposeParserError.invalidLine(line.number, line.raw)
                }
                continue
            }

            guard indent == 2, let currentSection = section else {
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }

            let pair = try keyValue(content, line: line.number)
            let name = pair.key

            switch currentSection {
            case "services":
                let parsed = try parseService(name: name, lines: lines, start: index + 1)
                services.append(parsed.service)
                index = parsed.nextIndex
            case "volumes":
                let parsed = try parseVolume(name: name, lines: lines, start: index + 1)
                volumes.append(parsed.volume)
                index = parsed.nextIndex
            case "networks":
                let parsed = try parseNetwork(name: name, lines: lines, start: index + 1)
                networks.append(parsed.network)
                index = parsed.nextIndex
            default:
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }
        }

        guard !services.isEmpty else {
            throw ComposeParserError.missingServices
        }

        return ComposeFile(project: project, services: services, volumes: volumes, networks: networks)
    }

    private func parseService(name: String, lines: [ParsedLine], start: Int) throws -> (service: ComposeService, nextIndex: Int) {
        var image: String?
        var environment: [String: String] = [:]
        var ports: [String] = []
        var volumes: [String] = []
        var networks: [String] = []
        var dependsOn: [String] = []
        var command: [String] = []
        var index = start

        while index < lines.count {
            let line = lines[index]
            guard line.indent >= 4 else { break }
            guard line.indent == 4 else {
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }

            let pair = try keyValue(line.content, line: line.number)
            switch pair.key {
            case "image":
                image = pair.value
                index += 1
            case "ports":
                let parsed = try parseList(lines: lines, start: index + 1, indent: 6)
                ports = parsed.values
                index = parsed.nextIndex
            case "volumes":
                let parsed = try parseList(lines: lines, start: index + 1, indent: 6)
                volumes = parsed.values
                index = parsed.nextIndex
            case "networks":
                let parsed = try parseList(lines: lines, start: index + 1, indent: 6)
                networks = parsed.values
                index = parsed.nextIndex
            case "depends_on":
                let parsed = try parseList(lines: lines, start: index + 1, indent: 6)
                dependsOn = parsed.values
                index = parsed.nextIndex
            case "command":
                if let value = pair.value {
                    command = splitShellWords(value)
                    index += 1
                } else {
                    let parsed = try parseList(lines: lines, start: index + 1, indent: 6)
                    command = parsed.values
                    index = parsed.nextIndex
                }
            case "environment":
                let parsed = try parseMap(lines: lines, start: index + 1, indent: 6)
                environment = parsed.values
                index = parsed.nextIndex
            default:
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }
        }

        guard let image else {
            throw ComposeParserError.missingImage(name)
        }

        return (
            ComposeService(
                name: name,
                image: image,
                environment: environment,
                ports: ports,
                volumes: volumes,
                networks: networks,
                dependsOn: dependsOn,
                command: command
            ),
            index
        )
    }

    private func parseVolume(name: String, lines: [ParsedLine], start: Int) throws -> (volume: ComposeVolume, nextIndex: Int) {
        var size: String?
        var index = start

        while index < lines.count {
            let line = lines[index]
            guard line.indent >= 4 else { break }
            guard line.indent == 4 else {
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }
            let pair = try keyValue(line.content, line: line.number)
            if pair.key == "size" {
                size = pair.value
            }
            index += 1
        }

        return (ComposeVolume(name: name, size: size), index)
    }

    private func parseNetwork(name: String, lines: [ParsedLine], start: Int) throws -> (network: ComposeNetwork, nextIndex: Int) {
        var isInternal = false
        var index = start

        while index < lines.count {
            let line = lines[index]
            guard line.indent >= 4 else { break }
            guard line.indent == 4 else {
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }
            let pair = try keyValue(line.content, line: line.number)
            if pair.key == "internal" {
                isInternal = pair.value == "true"
            }
            index += 1
        }

        return (ComposeNetwork(name: name, internal: isInternal), index)
    }

    private func parseList(lines: [ParsedLine], start: Int, indent: Int) throws -> (values: [String], nextIndex: Int) {
        var values: [String] = []
        var index = start

        while index < lines.count {
            let line = lines[index]
            guard line.indent >= indent else { break }
            guard line.indent == indent, line.content.hasPrefix("- ") else {
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }
            values.append(unquote(String(line.content.dropFirst(2)).trimmingCharacters(in: .whitespaces)))
            index += 1
        }

        return (values, index)
    }

    private func parseMap(lines: [ParsedLine], start: Int, indent: Int) throws -> (values: [String: String], nextIndex: Int) {
        var values: [String: String] = [:]
        var index = start

        while index < lines.count {
            let line = lines[index]
            guard line.indent >= indent else { break }
            guard line.indent == indent else {
                throw ComposeParserError.invalidLine(line.number, line.raw)
            }
            let pair = try keyValue(line.content, line: line.number)
            values[pair.key] = pair.value ?? ""
            index += 1
        }

        return (values, index)
    }
}

private struct ParsedLine {
    var number: Int
    var raw: String

    var indent: Int {
        raw.prefix(while: { $0 == " " }).count
    }

    var content: String {
        String(raw.dropFirst(indent))
    }
}

private func keyValue(_ content: String, line: Int) throws -> (key: String, value: String?) {
    guard let separator = content.firstIndex(of: ":") else {
        throw ComposeParserError.invalidLine(line, content)
    }

    let key = String(content[..<separator]).trimmingCharacters(in: .whitespaces)
    let rawValue = String(content[content.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
    return (key, rawValue.isEmpty ? nil : unquote(rawValue))
}

private func unquote(_ value: String) -> String {
    if value.count >= 2,
       let first = value.first,
       let last = value.last,
       (first == "\"" && last == "\"") || (first == "'" && last == "'") {
        return String(value.dropFirst().dropLast())
    }
    return value
}

private func stripComment(_ value: String) -> String {
    var inSingleQuote = false
    var inDoubleQuote = false
    for (offset, character) in value.enumerated() {
        if character == "'", !inDoubleQuote {
            inSingleQuote.toggle()
        } else if character == "\"", !inSingleQuote {
            inDoubleQuote.toggle()
        } else if character == "#", !inSingleQuote, !inDoubleQuote {
            return String(value.prefix(offset))
        }
    }
    return value
}

private func splitShellWords(_ value: String) -> [String] {
    value.split(separator: " ").map(String.init)
}
