//
//  Created by Derek Clarkson on 6/8/2022.
//

import Foundation

/// Using a protocol to drive the ``EndpointBuilder`` means that a variety of types can produce API endpoints.
public protocol EndpointSource {
    var apis: [Endpoint] { get }
}

/// Result builder for assembling end points for the server.
@resultBuilder
public enum EndpointBuilder {
    public static func buildOptional(_ endpoints: [Endpoint]?) -> [Endpoint] { endpoints ?? [] }
    public static func buildEither(first source: EndpointSource) -> [Endpoint] { source.apis }
    public static func buildEither(second source: EndpointSource) -> [Endpoint] { source.apis }
    public static func buildBlock(_ endpoints: EndpointSource...) -> [Endpoint] { endpoints.flatMap { $0.apis } }
}

// MARK: - Extensions

extension Endpoint: EndpointSource {
    public var apis: [Endpoint] { [self] }
}

extension Array: EndpointSource where Element == Endpoint {
    public var apis: [Endpoint] { self }
}
