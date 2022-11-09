//
//  Created by Derek Clarkson on 6/8/2022.
//

import Foundation

/// Using a protocol to drive the ``EndpointBuilder`` means that a variety of types can produce API endpoints.
public protocol EndpointSource {
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

extension HTTPEndpoint: EndpointSource {
    public var endpoints: [Endpoint] { [self] }
}

extension GraphQLEndpoint: EndpointSource {
    public var endpoints: [Endpoint] { [self] }
}

extension [Endpoint]: EndpointSource {
    public var endpoints: [Endpoint] { self }
}
