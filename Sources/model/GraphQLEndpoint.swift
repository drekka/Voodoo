//
//  File.swift
//
//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation
import NIOHTTP1

public struct GraphQLEndpoint: Endpoint {

    let method: HTTPMethod
    let selector: GraphQLSelector
    let response: HTTPResponse

    public init(_ method: HTTPMethod, _ graphQLSelector: GraphQLSelector, response: HTTPResponse = .ok()) {
        self.method = method
        selector = graphQLSelector
        self.response = response
    }

    public init(from _: Decoder) throws {
        method = .GET
        response = .ok()
        selector = .operationName("abc")
    }
}
