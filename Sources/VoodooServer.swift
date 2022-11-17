//
//  Created by Derek Clarkson.
//

import Foundation
import Hummingbird
import HummingbirdFoundation
import HummingbirdMustache
import NIOCore

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

/// The main Voodoo server.
public class VoodooServer {

    private let server: HBApplication
    private let verbose: Bool
    private var graphQLRouter: GraphQLRouter!

    public let graphQLPath: String

    public var url: URL {
        URL(string: "http://\(server.host):\(server.port)")!
    }

    /// Default initialiser for Voodoo.
    ///
    /// - parameters:
    ///     - portRange: The range of ports to launch on.
    ///     - graphQLPath: The request path that the GraphQL responder will observe for incoming GraphQL requests.
    ///     - useAnyAddr: If set to true, changes the IP of the server from 127.0.0.1 to 0.0.0.0. This is for use in
    ///     docker and other situations where the default home address will not work.
    ///     - templatePath: The path to the template folder where template will be loaded from.
    ///     - filePaths: A list of paths to directories where file will be searched for if there is no matching API endpoint found.
    ///     - verbose: When true, tells Voodoo to print more information about it's setup and the incoming requests.
    ///     - hummingbirdVerbose: Enables verbose mode on the internal Hummingbird server.
    ///     - endpoints: An optional list of endpoint to setup.
    public init(portRange: ClosedRange<Int> = 8080 ... 8090,
                graphQLPath: String = "/graphql",
                useAnyAddr: Bool = false,
                templatePath: URL? = nil,
                templateExtension: String = "json",
                filePaths: [URL]? = nil,
                verbose: Bool = false,
                hummingbirdVerbose: Bool = false,
                @EndpointBuilder endpoints: () -> [Endpoint] = { [] }) throws {

        self.verbose = verbose
        self.graphQLPath = graphQLPath

        // Setup middleware. middleware must be added before starting the server or
        // the middleware will execute after Hummingbird's ``TrieRouter``.
        // This is due to the way hummingbird wires middleware and the router together.
        // Also note the order is important.
        let middleware: [HBMiddleware] = [
            RequestLogger(verbose: verbose),
            NoResponseFoundMiddleware(),
            AdminConsole(),
        ]

        // Validate the file paths.
        try filePaths?.forEach { // Directories to search for files when there is no matching endpoint.
            if $0.fileSystemStatus != .isDirectory {
                throw VoodooError.directoryNotExists($0.filePath)
            }
        }

        // Initiate the mustache template renderer if it's been set.
        let mustacheEngine: HBMustacheLibrary
        if let templatePath {
            mustacheEngine = try HBMustacheLibrary(directory: templatePath.path, withExtension: templateExtension)
        } else {
            mustacheEngine = HBMustacheLibrary()
        }

        for nextPort in portRange {

            do {
                server = try HBApplication.start(on: nextPort,
                                                 useAnyAddr: useAnyAddr,
                                                 middleware: middleware,
                                                 mustacheEngine: mustacheEngine,
                                                 filePaths: filePaths,
                                                 verbose: verbose,
                                                 hummingbirdVerbose: hummingbirdVerbose)

                // Add any passed endpoints.
                add(endpoints)

                return // Exit init.

            } catch {

                switch error {
                case _ where error.isPortTakenError:
                    if verbose { print("💀 Port \(nextPort) busy, trying next port in range") }
                    continue

                case let error as VoodooError:
                    print("💀 Unexpected error: \(error.localizedDescription)")
                    throw error

                default:
                    print("💀 Unexpected error: \(error.localizedDescription)")
                    throw VoodooError.unexpectedError(error)
                }
            }
        }

        print("💀 Exhausted all ports in range \(portRange)")
        throw VoodooError.noPortAvailable(portRange.lowerBound, portRange.upperBound)
    }

    public func wait() {
        if verbose {
            print(#"💀 CTRL+C or "curl -X "POST" \#(url.absoluteString)/\#(AdminConsole.adminRoot)/\#(AdminConsole.shutdown)" to shutdown."#)
            print(#"💀 Have a nice day 🙂"#)
        } else {
            print(url.absoluteString)
        }
        server.wait()
    }

    // MARK: - Convenience registration

    /// Adds an array of endpoints generated by an ``EndpointBuilder``.
    ///
    /// - parameter endpoints: the generated closure that returns the endpoints to add.
    public func add(@EndpointBuilder _ endpoints: () -> [Endpoint]) {
        endpoints().forEach(add(_:))
    }

    /// Adds an array of endpoints.
    ///
    /// - parameter endpoints: An array of endpoints.
    public func add(_ endpoints: [Endpoint]) {
        endpoints.forEach(add(_:))
    }

    /// Adds the passed endpoint.
    ///
    /// - parameter endpoint: The end point to add.
    public func add(_ endpoint: Endpoint) {
        switch endpoint {
        case let endpoint as HTTPEndpoint:
            add(endpoint)
        case let endpoint as GraphQLEndpoint:
            add(endpoint)
        default:
            break
        }
    }

    /// Convenient function for defining a HTTP endpoint directly.
    public func add(_ method: HTTPMethod, _ path: String, response handler: @escaping (HTTPRequest, Cache) async -> HTTPResponse) {
        add(method, path, response: .dynamic(handler))
    }

    /// Adds a HTTP rest like endpoint.
    public func add(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok()) {
        add(HTTPEndpoint(method, path, response: response))
    }

    /// Convenient function for defining a GraphQL endpoint directly.
    public func add(_ method: HTTPMethod, _ graphQLSelector: GraphQLSelector, response handler: @escaping (HTTPRequest, Cache) async -> HTTPResponse) {
        add(method, graphQLSelector, response: .dynamic(handler))
    }

    /// Adds a GraphQL endpoint.
    public func add(_ method: HTTPMethod, _ selector: GraphQLSelector, response: HTTPResponse = .ok()) {
        add(GraphQLEndpoint(method, selector, response: response))
    }

    // MARK: - Core registration

    /// Adds a HTTP rest like endpoint.
    public func add(_ endpoint: HTTPEndpoint) {
        if verbose { print("💀 Adding endpoint:\(endpoint.method) \(endpoint.path)") }
        server.router.add(endpoint)
    }

    /// Adds a GraphQL endpoint.
    public func add(_ endpoint: GraphQLEndpoint) {

        // If the GraphQL router has not been setup then configure and install it.
        if graphQLRouter == nil {
            graphQLRouter = GraphQLRouter(verbose: verbose)
            server.router.get(graphQLPath) { request in
                try await self.graphQLRouter.execute(request: request)
            }
            server.router.post(graphQLPath) { request in
                try await self.graphQLRouter.execute(request: request)
            }
        }

        if verbose { print("💀 Adding GraphQL endpoint:\(endpoint.method) \(endpoint.selector)") }
        graphQLRouter.add(endpoint)
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
                      middleware: [HBMiddleware],
                      mustacheEngine: HBMustacheLibrary,
                      filePaths: [URL]?,
                      verbose _: Bool,
                      hummingbirdVerbose: Bool) throws -> HBApplication {

        let configuration = HBApplication.Configuration(
            address: .hostname(useAnyAddr ? "0.0.0.0" : "127.0.0.1", port: port),
            serverName: "Voodoo API simulator",
            logLevel: hummingbirdVerbose ? .trace : .critical
        )

        let server = HBApplication(configuration: configuration)

        // Add middleware. This must be done before starting the server or
        // the middleware will execute after Hummingbird's ``TrieRouter``.
        // This is due to the way hummingbird wires middleware and the router together.
        // Also note the order is important.
        middleware.forEach(server.middleware.add(_:))

        // File path middleware requires a server reference so we cannot set them up in advance.
        filePaths?.map { HBFileMiddleware($0.filePath, application: server) }.forEach(server.middleware.add(_:))

        // Setup resources and engines.
        server.cache = InMemoryCache()
        server.mustacheRenderer = mustacheEngine

        try server.start()
        return server
    }
}
