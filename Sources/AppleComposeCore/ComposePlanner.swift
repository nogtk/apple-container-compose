public struct ComposePlanner {
    public init() {}

    public func planUp(_ file: ComposeFile) -> [ShellCommand] {
        var commands: [ShellCommand] = []

        for network in file.networks {
            var arguments = ["network", "create"]
            if network.`internal` {
                arguments.append("--internal")
            }
            arguments.append(network.name)
            commands.append(ShellCommand(arguments: arguments))
        }

        for volume in file.volumes {
            var arguments = ["volume", "create"]
            if let size = volume.size {
                arguments += ["--size", size]
            }
            arguments.append(volume.name)
            commands.append(ShellCommand(arguments: arguments))
        }

        for service in orderedServices(file.services) {
            var arguments = ["run", "--detach", "--name", containerName(project: file.project, service: service.name)]

            for key in service.environment.keys.sorted() {
                arguments += ["--env", "\(key)=\(service.environment[key] ?? "")"]
            }
            for port in service.ports {
                arguments += ["--publish", port]
            }
            for volume in service.volumes {
                arguments += ["--volume", volume]
            }
            for network in service.networks {
                arguments += ["--network", network]
            }

            arguments.append(service.image)
            arguments += service.command
            commands.append(ShellCommand(arguments: arguments))
        }

        return commands
    }

    public func planDown(_ file: ComposeFile) -> [ShellCommand] {
        orderedServices(file.services).reversed().flatMap { service in
            let name = containerName(project: file.project, service: service.name)
            return [
                ShellCommand(arguments: ["stop", name]),
                ShellCommand(arguments: ["delete", name])
            ]
        }
    }

    private func orderedServices(_ services: [ComposeService]) -> [ComposeService] {
        var result: [ComposeService] = []
        var remaining = services
        var emitted = Set<String>()

        while !remaining.isEmpty {
            let ready = remaining.filter { Set($0.dependsOn).isSubset(of: emitted) }
            let batch = ready.isEmpty ? [remaining.removeFirst()] : ready
            for service in batch {
                if let index = remaining.firstIndex(where: { $0.name == service.name }) {
                    remaining.remove(at: index)
                }
                result.append(service)
                emitted.insert(service.name)
            }
        }

        return result
    }

    private func containerName(project: String, service: String) -> String {
        "\(project)-\(service)"
    }
}
