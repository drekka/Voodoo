import Foundation

/// Result builder for assembling multiple end points.
@resultBuilder
public enum EndpointBuilder {
    public static func buildOptional(_ endpoints: [Endpoint]?) -> [Endpoint] { endpoints ?? [] }
    public static func buildEither(first source: EndpointFactory) -> [Endpoint] { source.endpoints }
    public static func buildEither(second source: EndpointFactory) -> [Endpoint] { source.endpoints }
    public static func buildBlock(_ endpoints: EndpointFactory...) -> [Endpoint] { endpoints.flatMap(\.endpoints) }
}

