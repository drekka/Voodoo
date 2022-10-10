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

    public var address: URL { server.address }

    public init(portRange: ClosedRange<Int> = 8080 ... 8090,
                templatePath: URL? = nil,
                templateExtension: String = "json",
                filePaths: [URL]? = nil,
                verbose: Bool = false,
                @EndpointBuilder endpoints: () -> [Endpoint] = { [] }) throws {

        self.verbose = verbose

        for port in portRange {

            do {

                let configuration = HBApplication.Configuration(
                    address: .hostname("0.0.0.0", port: port), // Use the "everything" address so this server works in containers suck as docker.
                    serverName: "Simulcra API simulator",
                    logLevel: verbose ? .trace : .error
                )
                let server = HBApplication(configuration: configuration)

                // Add middleware. This must be done before starting the server or
                // the middleware will execute after Hummingbird's ``TrieRouter``.
                // This is due to the way hummingbird wires middleware and the router together.
                server.middleware.add(HostCapture()) // Captures the incoming 'Host' header for injecting into responses.
                server.middleware.add(RequestLogger(verbose: verbose))
                server.middleware.add(AdminConsole())
                try filePaths?.forEach { // Directories to search for files when there is no matching endpoint.
                    guard $0.fileSystemExists == .isDirectory else {
                        throw SimulcraError.directoryNotExists($0.relativePath)
                    }
                    server.middleware.add(HBFileMiddleware($0.relativePath, application: server))
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
                self.server = server

                // Add any passed endpoints.
                add(endpoints)

                return

            } catch {
                if error.isPortTakenError {
                    print("👻 Port \(port) busy, trying next port in range")
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
        var port = ""
        if let actualPort = address.port {
            port = "\(actualPort)"
        }
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
