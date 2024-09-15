import Foundation
import Hummingbird
import HummingbirdFoundation
import PathKit

// Voodoo extensions to Hummingbird.

extension HBApplication {

    /// Configures and starts the server on the specified port or throws an error if that fails.
    static func start(on port: Int,
                      useAnyAddr: Bool,
                      middleware: [HBMiddleware],
                      templateEngine: TemplateRenderer,
                      filePaths: [Path],
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
        filePaths.map { HBFileMiddleware($0.string, application: server) }.forEach(server.middleware.add(_:))

        // Setup resources and engines.
        server.cache = [:]
        server.templateRenderer = templateEngine
        server.delay = 0.0

        try server.start()
        return server
    }
}

extension HBApplication: ServerContext {

    public var port: Int {
        guard let port = configuration.address.port else {
            fatalError("💥💥💥 No port set on server 💥💥💥")
        }
        return port
    }

    public var delay: Double {
        get { extensions.get(\.delay) }
        set { extensions.set(\.delay, value: newValue) }
    }

    public var host: String {
        guard let host = configuration.address.host else {
            fatalError("💥💥💥 No host set on server 💥💥💥")
        }
        return host
    }

    public var cache: Cache {
        get { extensions.get(\.cache) }
        set { extensions.set(\.cache, value: newValue) }
    }

    var templateRenderer: any TemplateRenderer {
        get { extensions.get(\.templateRenderer) }
        set { extensions.set(\.templateRenderer, value: newValue) }
    }
}
