import XCTest
@testable import AppleComposeCore

final class PlannerTests: XCTestCase {
    func testUpCreatesResourcesAndRunsServicesInDependencyOrder() {
        let file = ComposeFile(
            project: "demo",
            services: [
                ComposeService(
                    name: "db",
                    image: "postgres:16",
                    environment: ["POSTGRES_PASSWORD": "secret"],
                    ports: [],
                    volumes: ["db-data:/var/lib/postgresql/data"],
                    networks: ["backend"],
                    dependsOn: [],
                    command: []
                ),
                ComposeService(
                    name: "web",
                    image: "nginx:latest",
                    environment: ["MODE": "dev"],
                    ports: ["8080:80"],
                    volumes: [],
                    networks: ["backend"],
                    dependsOn: ["db"],
                    command: ["nginx", "-g", "daemon off;"]
                )
            ],
            volumes: [ComposeVolume(name: "db-data", size: "2G")],
            networks: [ComposeNetwork(name: "backend", internal: false)]
        )

        let commands = ComposePlanner().planUp(file)

        XCTAssertEqual(commands.map(\.description), [
            "container network create backend",
            "container volume create --size 2G db-data",
            "container run --detach --name demo-db --env POSTGRES_PASSWORD=secret --volume db-data:/var/lib/postgresql/data --network backend postgres:16",
            "container run --detach --name demo-web --env MODE=dev --publish 8080:80 --network backend nginx:latest nginx -g daemon off;"
        ])
    }

    func testDownStopsAndDeletesServicesInReverseDependencyOrder() {
        let file = ComposeFile(
            project: "demo",
            services: [
                ComposeService(name: "db", image: "postgres:16", dependsOn: []),
                ComposeService(name: "web", image: "nginx:latest", dependsOn: ["db"])
            ]
        )

        let commands = ComposePlanner().planDown(file)

        XCTAssertEqual(commands.map(\.description), [
            "container stop demo-web",
            "container delete demo-web",
            "container stop demo-db",
            "container delete demo-db"
        ])
    }
}
