public struct ComposeFile: Equatable {
    public var project: String
    public var services: [ComposeService]
    public var volumes: [ComposeVolume]
    public var networks: [ComposeNetwork]

    public init(
        project: String = "app",
        services: [ComposeService],
        volumes: [ComposeVolume] = [],
        networks: [ComposeNetwork] = []
    ) {
        self.project = project
        self.services = services
        self.volumes = volumes
        self.networks = networks
    }
}

public struct ComposeService: Equatable {
    public var name: String
    public var image: String
    public var environment: [String: String]
    public var ports: [String]
    public var volumes: [String]
    public var networks: [String]
    public var dependsOn: [String]
    public var command: [String]

    public init(
        name: String,
        image: String,
        environment: [String: String] = [:],
        ports: [String] = [],
        volumes: [String] = [],
        networks: [String] = [],
        dependsOn: [String] = [],
        command: [String] = []
    ) {
        self.name = name
        self.image = image
        self.environment = environment
        self.ports = ports
        self.volumes = volumes
        self.networks = networks
        self.dependsOn = dependsOn
        self.command = command
    }
}

public struct ComposeVolume: Equatable {
    public var name: String
    public var size: String?

    public init(name: String, size: String? = nil) {
        self.name = name
        self.size = size
    }
}

public struct ComposeNetwork: Equatable {
    public var name: String
    public var `internal`: Bool

    public init(name: String, internal: Bool = false) {
        self.name = name
        self.internal = `internal`
    }
}

public struct ShellCommand: Equatable, CustomStringConvertible {
    public var executable: String
    public var arguments: [String]

    public init(_ executable: String = "container", _ arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }

    public init(arguments: [String]) {
        self.executable = "container"
        self.arguments = arguments
    }

    public var description: String {
        ([executable] + arguments).joined(separator: " ")
    }
}
