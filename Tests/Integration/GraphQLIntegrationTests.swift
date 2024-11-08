//
//  File.swift
//
//
//  Created by Derek Clarkson on 12/11/2022.
//

import Foundation
import Nimble
@testable import Voodoo
import XCTest

class GraphQLIntegrationTests: XCTestCase, IntegrationTesting {

    var server: VoodooServer!

    override func setUp() async throws {
        server = try VoodooServer()
    }

    func testSimpleOperationQuery() async {
        server.add(.GET, .operations("abc"), response: .ok())
        var urlComponents = URLComponents(url: server.url, resolvingAgainstBaseURL: false)!
        urlComponents.path = server.graphQLPath
        urlComponents.query = "query=query abc { a {b}}"
        let request = URLRequest(url: urlComponents.url!)
        _ = await executeAPICall(request, andExpectStatusCode: 200)
    }
}
