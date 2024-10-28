import Foundation

extension GraphQLEndpoint: DecodableEndpoint {

    static func canDecode(from decoder: Decoder) throws -> Bool {
        let container = try decoder.container(keyedBy: GraphQLEndpointKeys.self)
        return container.contains(.graphQL)
    }

    private enum GraphQLEndpointKeys: CodingKey {
        case graphQL
    }

    public init(from decoder: any Decoder) throws {
    }
}
