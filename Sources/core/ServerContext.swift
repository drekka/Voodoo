import Foundation

/// Provides access to the server's features.
protocol ServerContext {

    /// The port the server is running on.
    var port: Int { get }

    /// The global delay.
    var delay: Double { get }

    /// The current template render.
    var templateRenderer: any TemplateRenderer { get }

    /// Local in-memory cache for storing data between requests.
    var cache: Cache { get }
}
