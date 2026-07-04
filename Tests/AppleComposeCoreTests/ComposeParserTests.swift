import XCTest
@testable import AppleComposeCore

final class ComposeParserTests: XCTestCase {
    func testParsesServicesVolumesNetworksAndCommands() throws {
        let yaml = """
        project: demo
        services:
          web:
            image: nginx:latest
            ports:
              - "8080:80"
            environment:
              NODE_ENV: production
              FEATURE_FLAG: "true"
            volumes:
              - "site-data:/usr/share/nginx/html"
            networks:
              - frontend
            command:
              - nginx
              - -g
              - daemon off;
          redis:
            image: redis:7
        volumes:
          site-data:
            size: 1G
        networks:
          frontend:
            internal: true
        """

        let file = try ComposeParser().parse(yaml)

        XCTAssertEqual(file.project, "demo")
        XCTAssertEqual(file.services.map(\.name), ["web", "redis"])
        XCTAssertEqual(file.services[0].image, "nginx:latest")
        XCTAssertEqual(file.services[0].ports, ["8080:80"])
        XCTAssertEqual(file.services[0].environment, ["FEATURE_FLAG": "true", "NODE_ENV": "production"])
        XCTAssertEqual(file.services[0].volumes, ["site-data:/usr/share/nginx/html"])
        XCTAssertEqual(file.services[0].networks, ["frontend"])
        XCTAssertEqual(file.services[0].command, ["nginx", "-g", "daemon off;"])
        XCTAssertEqual(file.volumes, [ComposeVolume(name: "site-data", size: "1G")])
        XCTAssertEqual(file.networks, [ComposeNetwork(name: "frontend", internal: true)])
    }
}
