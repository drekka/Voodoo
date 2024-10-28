import Foundation

/// A protocol that lets other types generate end points.
///
/// This is mostly used by the ``EndpointBuilder``.
public protocol EndpointFactory {

    /// Returns the endpoints.
    var endpoints: [Endpoint] { get }
}

// MARK: - Extensions

/// Allows a ``HTTPEndpoint`` to generate itself as an ``EndpointFactory`` list.
extension HTTPEndpoint: EndpointFactory {
    public var endpoints: [Endpoint] { [self] }
}

/// Allows a ``GraphQLEndpoint`` to generate itself as an ``EndpointFactory``.
extension GraphQLEndpoint: EndpointFactory {
    public var endpoints: [Endpoint] { [self] }
}

/// Allows an array of ``Endpoint``s to return itself as an ``EndpointFactory``.
extension [Endpoint]: EndpointFactory {
    public var endpoints: [Endpoint] { self }
}

