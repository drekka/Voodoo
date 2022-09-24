//
//  Created by Derek Clarkson.
//

import Hummingbird
import HummingbirdMustache
import Network
import UIKit

/// The main Simulcra server.
public class MockServer {

    private let server: HBApplication

    public var address: URL { server.address }

    public init(portRange: ClosedRange<Int> = 8080 ... 8090,
                templatePath: URL? = nil,
                templateExtension: String = "json",
                verbose: Bool = false,
                @EndpointBuilder endpoints: () -> [Endpoint] = { [] }) throws {

        for port in portRange {

            do {

                let configuration = HBApplication.Configuration(address: .hostname(port: port), serverName: "Simulcra API simulator")
                let server = HBApplication(configuration: configuration)

                // Add middleware. This must be done before starting the server or
                // the middleware will execute after Hummingbird's ``TrieRouter``.
                // This is due to the way hummingbird wires middleware and the router together.
                server.middleware.add(AdminConsole())
                server.middleware.add(RequestLogger(verbose: verbose))
                server.middleware.add(NoResponseFoundMiddleware())

                // Setup an in-memory cache.
                server.cache = InMemoryCache()

                // Initiate the mustache template renderer if it's been set.
                if let templatePath = templatePath {
                    server.mustacheRenderer = try HBMustacheLibrary(directory: templatePath.path, withExtension: templateExtension)
                } else {
                    server.mustacheRenderer = HBMustacheLibrary()
                }

                try server.start()
                self.server = server

                // Add any passed endpoints.
                add(endpoints)

                return

            } catch {
                if error as? NWError == NWError.posix(.EADDRINUSE) {
                    print("👻 Port \(port) busy, trying next port in range")
                    continue
                }

                print("👻 Unexpected error: \(error.localizedDescription)")
                throw MockServerError.unexpectedError(error)
            }
        }

        print("👻 Exhausted all ports in range \(portRange)")
        throw MockServerError.noPortAvailable
    }

    // MARK: - Convenience registration

    public func add(@EndpointBuilder _ endpoints: () -> [Endpoint]) {
        endpoints().forEach { add($0.method, $0.path, response: $0.response) }
    }

    public func add(_ endpoints: [Endpoint]) {
        endpoints.forEach { add($0.method, $0.path, response: $0.response) }
    }

    public func add(_ endpoint: Endpoint) {
        add(endpoint.method, endpoint.path, response: endpoint.response)
    }

    public func add(_ method: HTTPMethod, _ path: String, response handler: @escaping (HTTPRequest, Cache) async -> HTTPResponse) {
        add(method, path, response: .dynamic(handler))
    }

    // MARK: - Core registration

    public func add(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok()) {
        server.router.add(method, path, response: response)
    }

    // MARK: - Server functions

    public func stop() {
        server.stop()
    }
}
