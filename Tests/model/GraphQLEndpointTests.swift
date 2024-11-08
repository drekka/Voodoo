//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation
import Nimble
import NIOHTTP1
@testable import Voodoo
import XCTest
import Yams

class GraphQLEndpointTests: XCTestCase {

    func testInitWithArgs() {
        let endpoint = GraphQLEndpoint(.GET, .operations("abc"), response: .ok(body: .json([:])))
        expect(endpoint.method) == .GET
        expect(endpoint.selector) == .operations("abc")
        expect(endpoint.response) == .ok(body: .json([:]))
    }

    func testCanDecode() throws {

        let goodYaml = "graphQL: ~"
        let badYaml = "xxx: ~"

        struct Container: Decodable {
            let canDecode: Bool
            init(from decoder: Decoder) throws {
                canDecode = try GraphQLEndpoint.canDecode(from: decoder)
            }
        }

        let container1 = try YAMLDecoder().decode(Container.self, from: goodYaml)
        expect(container1.canDecode) == true
        let container2 = try YAMLDecoder().decode(Container.self, from: badYaml)
        expect(container2.canDecode) == false
    }

    func testDecodeOperationSelector() throws {
        let yaml = #"""
        graphQL:
          method: get
          operations: getConfig
        response:
          status: 200
        """#

        let endpoint = try YAMLDecoder().decode(GraphQLEndpoint.self, from: yaml, userInfo: mockUserInfo())

        expect(endpoint.method) == .GET
        expect(endpoint.selector) == .operations("getConfig")
        expect(endpoint.response) == .ok()
    }

    func testDecodeQuerySelector() throws {
        let yaml = #"""
        graphQL:
          method: get
          query: query { book }
        response:
          status: 200
        """#

        let endpoint = try YAMLDecoder().decode(GraphQLEndpoint.self, from: yaml, userInfo: mockUserInfo())

        expect(endpoint.method) == .GET
        expect(endpoint.selector) == .query(try GraphQLRequest(query: "query { book }"))
        expect(endpoint.response) == .ok()
    }

    func testDecodeMissingSelector() throws {
        try expectYML(#"""
                      graphQL:
                        method: get
                      response:
                        status: 200
                      """#,
                      toFailWithDataCorrupt: "Expected to find 'operations' or 'query'")
    }

    func testDecodeWithNoResponse() throws {
        try expectYML(#"""
                      graphQL:
                        method: get
                        operations: getConfig
                      """#,
                      toFailWithDataCorrupt: "Expected to find 'response', 'javascript' or 'javascriptFile'")
    }

    // MARK: - Support

    private func expectYML(file: FileString = #file, line: UInt = #line, _ yml: String, toFailWithDataCorrupt expectedMessage: String) throws {
        do {
            _ = try YAMLDecoder().decode(GraphQLEndpoint.self, from: yml, userInfo: mockUserInfo())
            fail("Error not thrown", file: file, line: line)
        } catch {
            guard case DecodingError.dataCorrupted(let context) = error else {
                fail("Incorrect exception \(error)", file: file, line: line)
                return
            }
            expect(file: file, line: line, context.debugDescription) == expectedMessage
        }
    }
}
