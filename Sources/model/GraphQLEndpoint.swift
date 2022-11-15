//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation
import NIOHTTP1

/// The definition of a GraphQL endpoint to be mocked with it's response.
public struct GraphQLEndpoint {

    let method: HTTPMethod
    let selector: GraphQLSelector
    let response: HTTPResponse

    public init(_ method: HTTPMethod, _ graphQLSelector: GraphQLSelector, response: HTTPResponse) {
        self.method = method
        selector = graphQLSelector
        self.response = response
    }
}

extension GraphQLEndpoint: Endpoint {

    public static func canDecode(from decoder: Decoder) throws -> Bool {
        let container = try decoder.container(keyedBy: EndpointKeys.self)
        return container.contains(.graphQL)
    }

    private enum EndpointKeys: String, CodingKey {
        case graphQL
    }

    private enum SelectorKeys: String, CodingKey {
        case method
        case operations
        case query
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: EndpointKeys.self)
        let selectorContainer = try container.nestedContainer(keyedBy: SelectorKeys.self, forKey: .graphQL)

        method = try selectorContainer.decode(HTTPMethod.self, forKey: .method)

        if let operation = try selectorContainer.decodeIfPresent(String.self, forKey: .operations) {
            selector = .operations(operation)
        } else if let operations = try selectorContainer.decodeIfPresent([String].self, forKey: .operations) {
            selector = .operations(operations)
        } else if let query = try selectorContainer.decodeIfPresent(String.self, forKey: .query) {
            selector = .query(try GraphQLRequest(query: query))
        } else {
            let message = "Expected to find '\(SelectorKeys.operations.stringValue)' or '\(SelectorKeys.query.stringValue)'"
            print("💀 Error: Reading endpoint definition at \(container.codingPath.map(\.stringValue)) - \(message)")
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: message)
            throw DecodingError.dataCorrupted(context)
        }

        if decoder.verbose { print("💀 Found graphQL endpoint \(method) - \(selector)") }

        response = try decoder.decodeResponse()
    }
}
