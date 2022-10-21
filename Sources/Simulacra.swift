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

/// The main Simulacra server.
public class Simulacra {

    private let server: HBApplication
    private let verbose: Bool

    public var url: URL {
        URL(string: "http://\(server.host):\(server.port)")!
    }

    public init(portRange: ClosedRange<Int> = 8080 ... 8090,
                useAnyAddr: Bool = false,
                templatePath: URL? = nil,
                templateExtension: String = "json",
                filePaths: [URL]? = nil,
                verbose: Bool = false,
                hummingbirdVerbose: Bool = false,
                @EndpointBuilder endpoints: () -> [Endpoint] = { [] }) throws {

        self.verbose = verbose
        let finalEndpoints = endpoints()

        for nextPort in portRange {

            do {
                server = try HBApplication.start(on: nextPort,
                                                 useAnyAddr: useAnyAddr,
                                                 withTemplatePath: templatePath,
                                                 templateExtension: templateExtension,
                                                 filePaths: filePaths,
                                                 verbose: verbose,
                                                 hummingbirdVerbose: hummingbirdVerbose,
                                                 endpoints: finalEndpoints)
                return // Exit init.

            } catch {
                if error.isPortTakenError {
                    print("👻 Port \(nextPort) busy, trying next port in range")
                    continue
                }

                print("👻 Unexpected error: \(error.localizedDescription)")
                throw SimulacraError.unexpectedError(error)
            }
        }

        print("👻 Exhausted all ports in range \(portRange)")
        throw SimulacraError.noPortAvailable
    }

    public func wait() {
        if verbose {
            print(#"👻 CTRL+C or "curl \#(url.absoluteString)/\#(AdminConsole.adminRoot)/\#(AdminConsole.shutdown)" to shutdown."#)
            print(#"👻 Have a nice day 🙂"#)
        } else {
            print(url.absoluteString)
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
                      useAnyAddr: Bool,
                      withTemplatePath templatePath: URL?,
                      templateExtension: String,
                      filePaths: [URL]?,
                      verbose: Bool,
                      hummingbirdVerbose: Bool,
                      endpoints: [Endpoint]) throws -> HBApplication {

        let configuration = HBApplication.Configuration(
            address: .hostname(useAnyAddr ? "0.0.0.0" : "127.0.0.1", port: port),
            serverName: "Simulacra API simulator",
            logLevel: hummingbirdVerbose ? .trace : .error
        )
        let server = HBApplication(configuration: configuration)

        // Add middleware. This must be done before starting the server or
        // the middleware will execute after Hummingbird's ``TrieRouter``.
        // This is due to the way hummingbird wires middleware and the router together.
        server.middleware.add(RequestLogger(verbose: verbose))
        server.middleware.add(AdminConsole())
        try filePaths?.forEach { // Directories to search for files when there is no matching endpoint.
            guard $0.fileSystemStatus == .isDirectory else {
                throw SimulacraError.directoryNotExists($0.filePath)
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
