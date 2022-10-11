//
//  Created by Derek Clarkson.
//

import Foundation
import Hummingbird
import HummingbirdFoundation
import HummingbirdMustache

#if os(macOS) || os(iOS)
    import Network
#endif

extension Error {
    var isPortTakenError: Bool {
        #if os(iOS)
            return self as? NWError == .posix(.EADDRINUSE)
        #else
            return (self as? IOError)?.errnoCode == POSIXErrorCode.EADDRINUSE.rawValue
        #endif
    }
}

/// The main Simulcra server.
public class Simulcra {

    private let server: HBApplication
    private let verbose: Bool

    public var port: Int { server.port }

    public init(portRange: ClosedRange<Int> = 8080 ... 8090,
                templatePath: URL? = nil,
                templateExtension: String = "json",
                filePaths: [URL]? = nil,
                verbose: Bool = false,
                @EndpointBuilder endpoints: () -> [Endpoint] = { [] }) throws {

        self.verbose = verbose
        let finalEndpoints = endpoints()

        for nextPort in portRange {

            do {
                server = try HBApplication.start(on: nextPort,
                                                 withTemplatePath: templatePath,
                                                 templateExtension: templateExtension,
                                                 filePaths: filePaths,
                                                 verbose: verbose,
                                                 endpoints: finalEndpoints)
                return // Exit init.

            } catch {
                if error.isPortTakenError {
                    print("👻 Port \(nextPort) busy, trying next port in range")
                    continue
                }

                print("👻 Unexpected error: \(error.localizedDescription)")
                throw SimulcraError.unexpectedError(error)
            }
        }

        print("👻 Exhausted all ports in range \(portRange)")
        throw SimulcraError.noPortAvailable
    }

    public func wait() {
        if verbose {
            print(#"👻 CTRL+C or "curl <server-address>:\#(port)/\#(AdminConsole.adminRoot)/\#(AdminConsole.shutdown)" to shutdown."#)
            print(#"👻 Have a nice day 🙂"#)
        } else {
            print("port:\(port)")
        }
        server.wait()
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
        if verbose {
            print(#"👻 Adding endpoint:\#(method) \#(path)"#)
        }
        server.router.add(method, path, response: response)
    }

    // MARK: - Server functions

    public func stop() {
        server.stop()
    }
}

extension HBApplication {

    /// Configures and starts the server on the specified port or throws an error if that fails.
    static func start(on port: Int,
                      withTemplatePath templatePath: URL?,
                      templateExtension: String,
                      filePaths: [URL]?,
                      verbose: Bool,
                      endpoints: [Endpoint]) throws -> HBApplication {

        let configuration = HBApplication.Configuration(
            address: .hostname("0.0.0.0", port: port), // Use the "everything" address so this server works in containers suck as docker.
            serverName: "Simulcra API simulator",
            logLevel: verbose ? .trace : .error
        )
        let server = HBApplication(configuration: configuration)

        // Add middleware. This must be done before starting the server or
        // the middleware will execute after Hummingbird's ``TrieRouter``.
        // This is due to the way hummingbird wires middleware and the router together.
        server.middleware.add(RequestLogger(verbose: verbose))
        server.middleware.add(AdminConsole())
        try filePaths?.forEach { // Directories to search for files when there is no matching endpoint.
            guard $0.fileSystemStatus == .isDirectory else {
                throw SimulcraError.directoryNotExists($0.filePath)
            }
            server.middleware.add(HBFileMiddleware($0.filePath, application: server))
        }
        server.middleware.add(NoResponseFoundMiddleware())

        // Setup an in-memory cache.
        server.cache = InMemoryCache()

        // Initiate the mustache template renderer if it's been set.
        if let templatePath {
            server.mustacheRenderer = try HBMustacheLibrary(directory: templatePath.path, withExtension: templateExtension)
        } else {
            server.mustacheRenderer = HBMustacheLibrary()
        }

        try server.start()

        // Add any passed endpoints.
        endpoints.forEach {
            if verbose {
                print(#"👻 Adding endpoint:\#($0.method) \#($0.path)"#)
            }
            server.router.add($0.method, $0.path, response: $0.response)
        }

        return server
    }
}
