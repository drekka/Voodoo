//
//  File.swift
//
//
//  Created by Derek Clarkson on 9/11/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import Voodoo
import XCTest

class GraphQLRouterTests: XCTestCase {

    private var router: GraphQLRouter!

    override func setUp() {
        super.setUp()
        router = GraphQLRouter(verbose: true)
    }

    func testNotEndpoint() async throws {
        let request = HBRequest.mock(query: "query=query getConfig { a }")
        do {
            _ = try await router.execute(request: request)
        } catch VoodooError.noGraphQLEndpoint {
            // This is good.
        }
    }

    func testMissMatchMethod() async throws {
        router.add(GraphQLEndpoint(.GET, .operationName("getConfig"), response: .ok()))
        let request = HBRequest.mock(.POST,
                                     headers: [("content-type", "application/json")],
                                     body: #"""
                                     {
                                         "query":"query getConfig { a }"
                                     }
                                     """#)
        do {
            _ = try await router.execute(request: request)
        } catch VoodooError.noGraphQLEndpoint {
            // This is good.
        }
    }

    func testOperationEndpoint() async throws {
        router.add(GraphQLEndpoint(.GET, .operationName("getConfig"), response: .ok()))
        let request = HBRequest.mock(query: "query=query getConfig { a }")
        let response = try await router.execute(request: request)
        expect(response.status) == .ok
    }

    func testSelectorEndpoint() async throws {
        router.add(GraphQLEndpoint(.GET, .query(try GraphQLRequest(query: "query getConfig { a }")), response: .ok()))
        let request = HBRequest.mock(query: "query=query getConfig { a }")
        let response = try await router.execute(request: request)
        expect(response.status) == .ok
    }
}
