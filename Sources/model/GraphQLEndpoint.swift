//
//  File.swift
//
//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation
import NIOHTTP1

/// The definition of a GraphQL endpoint to be mocked with it's response.
public struct GraphQLEndpoint: Endpoint {

    let method: HTTPMethod
    let selector: GraphQLSelector
    let response: HTTPResponse

    private enum EndpointKeys: String, CodingKey {
        case graphQL
    }

    private enum SelectorKeys: String, CodingKey {
        case method
        case operation
        case selector
    }

    public init(_ method: HTTPMethod, _ graphQLSelector: GraphQLSelector, response: HTTPResponse) {
        self.method = method
        selector = graphQLSelector
        self.response = response
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: EndpointKeys.self)
        let selectorContainer = try container.nestedContainer(keyedBy: SelectorKeys.self, forKey: .graphQL)

        method = try selectorContainer.decode(HTTPMethod.self, forKey: .method)

        if let operationName = try selectorContainer.decodeIfPresent(String.self, forKey: .operation) {
            selector = .operationName(operationName)
        } else if let query = try selectorContainer.decodeIfPresent(String.self, forKey: .selector) {
            selector = .selector(try GraphQLRequest(query: query))
        } else {
            let context = DecodingError.Context(codingPath: container.codingPath,
                                                debugDescription: "Expected to find '\(SelectorKeys.operation.stringValue)' or '\(SelectorKeys.selector.stringValue)'")
            throw DecodingError.dataCorrupted(context)
        }

        response = try decoder.decodeResponse()
    }
}

