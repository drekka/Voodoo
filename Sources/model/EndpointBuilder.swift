import Foundation

/// Using a protocol to drive the ``EndpointBuilder`` means that a variety of types can produce API endpoints.
public protocol EndpointSource {

    /// Returns a list of endpoints.
    var endpoints: [Endpoint] { get }
}

/// Result builder for assembling end points for the server.
@resultBuilder
public enum EndpointBuilder {
    public static func buildOptional(_ endpoints: [Endpoint]?) -> [Endpoint] { endpoints ?? [] }
    public static func buildEither(first source: EndpointSource) -> [Endpoint] { source.endpoints }
    public static func buildEither(second source: EndpointSource) -> [Endpoint] { source.endpoints }
    public static func buildBlock(_ endpoints: EndpointSource...) -> [Endpoint] { endpoints.flatMap(\.endpoints) }
}

// MARK: - Extensions

/// Allows a ``HTTPEndpoint`` to generate itself as an ``EndpointSource`` list.
extension HTTPEndpoint: EndpointSource {
    public var endpoints: [Endpoint] { [self] }
}

/// Allows a ``GraphQLEndpoint`` to generate itself as an ``EndpointSource``.
extension GraphQLEndpoint: EndpointSource {
    public var endpoints: [Endpoint] { [self] }
}

/// Allows an array of ``Endpoint``s to return itself as an ``EndpointSource``.
extension [Endpoint]: EndpointSource {
    public var endpoints: [Endpoint] { self }
}
