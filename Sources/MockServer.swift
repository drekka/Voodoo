//
//  Created by Derek Clarkson.
//

import Hummingbird
import HummingbirdMustache
import Network
import UIKit

/// The main Simulcra server.
public class MockServer {

    private var server: HBApplication!
    private let hostName = "127.0.0.1"
    private var pendingEndpoints: [Endpoint]!
    private let templatePath: URL?
    private let verbose: Bool

    public var address: URL? { server?.address }

    public init(templatePath: URL? = nil, verbose: Bool = false) {
        self.templatePath = templatePath
        self.verbose = verbose
    }

    public func start(portRange: ClosedRange<Int> = 8080...8090) throws -> URL {
        for port in portRange {
            let server = try createServer(onPort: port)

            // Add middleware. This must occur before starting or the router will execute first.
            server.middleware.add(AdminConsole())
            server.middleware.add(RequestLogger(verbose: verbose))
            server.middleware.add(NoResponseFoundMiddleware())

            // Now start the server.
            do {
                try server.start()
                guard let address = server.address else {
                    print("👻 Server started without an address, trying next port in range")
                    continue
                }

                // Store the started server and return it's address.
                pendingEndpoints = nil
                self.server = server
                return address

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

    func add(_ endpoint: Endpoint) {
        // If the server has not been started then cache the endpoint for when it is.
        guard let server = server else {
            if pendingEndpoints == nil {
                pendingEndpoints = []
            }
            pendingEndpoints.append(endpoint)
            return
        }

        // Otherwise just add the endpoint.
        server.router.add(endpoint)
    }

    func stop() {
        server?.stop()
    }

    private func createServer(onPort port: Int) throws -> HBApplication {
        let configuration = HBApplication.Configuration(address: .hostname(hostName, port: port))
        let server = HBApplication(configuration: configuration)

        // Add middleware. This must be done before starting the server or
        // the middleware will execute after Hummingbird's ``TrieRouter``.
        // This is a result of the way hummingbird wires middleware and the router
        // together.

        // Setup an in-memory cache.
        server.cache = InMemoryCache()

        // Initiate the mustache template renderer if it's been set.
        if let templatePath = templatePath {
            server.mustacheRenderer = try HBMustacheLibrary(directory: templatePath.path, withExtension: "json")
        }

        // Add any pre-registered mocks.
        pendingEndpoints?.forEach { server.router.add($0) }

        return server
    }
}
