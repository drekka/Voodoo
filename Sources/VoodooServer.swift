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

    /// Analyses the error to see if this error is the one thrown when a port is busy.
    var isPortTaken: Bool {
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
    private var graphQLRouter: GraphQLRouter!

    /// Gets or sets the delay for all subsequent requests.
    public var delay: Double {
        get { server.delay }
        set { server.delay = newValue }
    }

    /// The path to listen for GraphQL queries on.
    ///
    /// By default this is `/graphql`.
    public let graphQLPath: String

    /// Returns the URL of the started server.
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
    ///     - templateExtension: The extension to use for templates. By default this is `json`.
    ///     - filePaths: A list of paths to directories where file will be searched for if there is no matching API endpoint found.
    ///     - endpoints: An optional list of endpoint to setup.
    public init(portRange: ClosedRange<Int> = 8080 ... 8090,
                graphQLPath: String = "/graphql",
                useAnyAddr: Bool = false,
                templatePath: URL? = nil,
                templateExtension: String = "json",
                filePaths: [URL]? = nil,
                @EndpointBuilder endpoints: () -> [Endpoint] = { [] }) throws
    {

        self.graphQLPath = graphQLPath

        // Setup middleware. middleware must be added before starting the server or
        // the middleware will execute after Hummingbird's ``TrieRouter``.
        // This is due to the way hummingbird wires middleware and the router together.
        // Also note the order is important.
        let middleware: [HBMiddleware] = [
            RequestLogger(),
            NoResponseFoundMiddleware(),
        ]

        // Validate the file paths.
        try filePaths?.forEach { // Directories to search for files when there is no matching endpoint.
            if $0.fileSystemStatus != .directory {
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
                                                 filePaths: filePaths)

                // Add any passed endpoints.
                add(endpoints)

                // Add the admin commands.
                addAdminConsole()

                return // Exit init.

            } catch {

                switch error {
                case _ where error.isPortTaken:
                    voodooLog(level: .debug, "Port \(nextPort) busy, trying next port in range")
                    continue

                case let error as VoodooError:
                    voodooLog("Unexpected error: \(error.localizedDescription)")
                    throw error

                default:
                    voodooLog("Unexpected error: \(error.localizedDescription)")
                    throw VoodooError.unexpectedError(error)
                }
            }
        }

        voodooLog("Exhausted all ports in range \(portRange)")
        throw VoodooError.noPortAvailable(portRange.lowerBound, portRange.upperBound)
    }

    /// Called from the command line driver this instructs the server to keep listening for requests until requested to stop.
    public func wait() {
        if voodooLogLevel == .server {
            voodooLog(level: .server, url.absoluteString)
        } else {
            voodooLog(#"CTRL+C or 'curl -X "POST" \#(url.absoluteString)\#(VoodooServer.adminShutdown)' to shutdown."#)
            voodooLog(#"Have a nice day."#)
        }
        server.wait()
    }

    // MARK: - Endpoints

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

    // MARK: - Endpoint types

    /// Convenient function for defining a HTTP endpoint directly.
    ///
    /// - parameters:
    ///   - method: The `HTTPMethod` to watch for.
    ///   - path: The path to watch. May contains wildcard placeholders for path elements. Placeholders
    ///   are defined with a leading `:` character and the name of a variable which that path element will be stored under.
    ///   For example a path of `/a/:productID` will respond to `/a/1234`, storing `1234` under the key `productID` in the requests ``HTTPRequest/pathParameters``.
    ///   - handler: The closure which is executed to generate the actual response.
    public func add(_ method: HTTPMethod, _ path: String, response handler: @escaping (HTTPRequest, Cache) async -> HTTPResponse) {
        add(method, path, response: .dynamic(handler))
    }

    /// Adds a HTTP rest like endpoint.
    ///
    /// - parameters:
    ///   - method: The `HTTPMethod` to watch for.
    ///   - path: The path to watch. May contains wildcard placeholders for path elements. Placeholders
    ///   are defined with a leading `:` character and the name of a variable which that path element will be stored under.
    ///   For example a path of `/a/:productID` will respond to `/a/1234`, storing `1234` under the key `productID` in the requests ``HTTPRequest/pathParameters``.
    ///   - response: The ``HTTPResponse`` to return.
    public func add(_ method: HTTPMethod, _ path: String, response: HTTPResponse = .ok()) {
        add(HTTPEndpoint(method, path, response: response))
    }

    /// Convenient function for defining a GraphQL endpoint directly.
    ///
    /// - parameters:
    ///   - method: The `HTTPMethod` to watch for.
    ///   - graphQLSelector: The selector that will identify the request to respond to.
    ///   are defined with a leading `:` character and the name of a variable which that path element will be stored under.
    ///   For example a path of `/a/:productID` will respond to `/a/1234`, storing `1234` under the key `productID` in the requests ``HTTPRequest/pathParameters``.
    ///   - handler: The closure which is executed to generate the actual response.
    public func add(_ method: HTTPMethod, _ graphQLSelector: GraphQLSelector, response handler: @escaping (HTTPRequest, Cache) async -> HTTPResponse) {
        add(method, graphQLSelector, response: .dynamic(handler))
    }

    /// Adds a GraphQL endpoint.
    ///
    /// - parameters:
    ///   - method: The `HTTPMethod` to watch for.
    ///   - graphQLSelector: The selector that will identify the request to respond to.
    ///   are defined with a leading `:` character and the name of a variable which that path element will be stored under.
    ///   For example a path of `/a/:productID` will respond to `/a/1234`, storing `1234` under the key `productID` in the requests ``HTTPRequest/pathParameters``.
    ///   - response: The ``HTTPResponse`` to return.
    public func add(_ method: HTTPMethod, _ selector: GraphQLSelector, response: HTTPResponse = .ok()) {
        add(GraphQLEndpoint(method, selector, response: response))
    }

    /// Adds a HTTP rest like endpoint.
    ///
    /// - parameter endpoint: The ``HTTPEndpoint`` to add.
    public func add(_ endpoint: HTTPEndpoint) {
        voodooLog("Adding endpoint:\(endpoint.method) \(endpoint.path)")
        server.router.add(endpoint)
    }

    /// Adds a GraphQL endpoint.
    ///
    /// - parameter endpoint: The ``GraphQLEndpoint`` to add.
    public func add(_ endpoint: GraphQLEndpoint) {

        // If the GraphQL router has not been setup then configure and install it.
        if graphQLRouter == nil {
            graphQLRouter = GraphQLRouter()
            server.router.get(graphQLPath) { request in
                try await self.graphQLRouter.execute(request: request)
            }
            server.router.post(graphQLPath) { request in
                try await self.graphQLRouter.execute(request: request)
            }
        }

        voodooLog("Adding GraphQL endpoint:\(endpoint.method) \(endpoint.selector)")
        graphQLRouter.add(endpoint)
    }

    // MARK: - Server functions

    /// Stops the server.
    public func stop() {
        voodooLog("Telling server to stop")
        server.stop()
    }
}

extension HBApplication {

    /// Configures and starts the server on the specified port or throws an error if that fails.
    static func start(on port: Int,
                      useAnyAddr: Bool,
                      middleware: [HBMiddleware],
                      mustacheEngine: HBMustacheLibrary,
                      filePaths: [URL]?) throws -> HBApplication
    {

        let configuration = HBApplication.Configuration(
            address: .hostname(useAnyAddr ? "0.0.0.0" : "127.0.0.1", port: port),
            serverName: "Voodoo API simulator",
            logLevel: voodooLogLevel == .internal ? .trace : .critical
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
        server.cache = Cache()
        server.mustacheRenderer = mustacheEngine
        server.delay = 0.0

        try server.start()
        return server
    }
}
