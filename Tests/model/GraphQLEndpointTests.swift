//
//  File.swift
//
//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation
import Nimble
import NIOHTTP1
@testable import SimulacraCore
import XCTest
import Yams

class GraphQLEndpointTests: XCTestCase {

    func testInitWithArgs() {
        let endpoint = GraphQLEndpoint(.GET, .operationName("abc"), response: .ok(body: .json([:])))
        expect(endpoint.method) == .GET
        expect(endpoint.selector) == .operationName("abc")
        expect(endpoint.response) == .ok(body: .json([:]))
    }

    func testDecodeOperationSelector() throws {
        let yaml = #"""
        graphQL:
          method: get
          operation: getConfig
        response:
          status: 200
        """#

        let endpoint = try YAMLDecoder().decode(GraphQLEndpoint.self, from: yaml, userInfo: userInfo())

        expect(endpoint.method) == .GET
        expect(endpoint.selector) == .operationName("getConfig")
        expect(endpoint.response) == .ok()
    }

    func testDecodeQuerySelector() throws {
        let yaml = #"""
        graphQL:
          method: get
          selector: query { book }
        response:
          status: 200
        """#

        let endpoint = try YAMLDecoder().decode(GraphQLEndpoint.self, from: yaml, userInfo: userInfo())

        expect(endpoint.method) == .GET
        expect(endpoint.selector) == .selector(try GraphQLRequest(query: "query { book }"))
        expect(endpoint.response) == .ok()
    }

    func testDecodeMissingSelector() throws {
        try expectYML(#"""
                  graphQL:
                    method: get
                  response:
                    status: 200
                  """#,
                  toFailWithDataCorrupt: "Expected to find 'operation' or 'selector'")
    }

    func testDecodeWithNoResponse() throws {
        try expectYML(#"""
                      graphQL:
                        method: get
                        operation: getConfig
                      """#,
                      toFailWithDataCorrupt: "Expected to find 'response', 'javascript' or 'javascriptFile'")
    }

    // MARK: - Support

    private func expectYML(file: StaticString = #file, line: UInt = #line, _ yml: String, toFailWithDataCorrupt expectedMessage: String) throws {
        do {
            _ = try YAMLDecoder().decode(GraphQLEndpoint.self, from: yml, userInfo: userInfo())
            fail("Error not thrown", file: file, line: line)
        } catch {
            guard case DecodingError.dataCorrupted(let context) = error else {
                fail("Incorrect exception \(error)", file: file, line: line)
                return
            }
            expect(file: file, line: line, context.debugDescription) == expectedMessage
        }
    }

    private func userInfo() -> [CodingUserInfoKey: Any] {
        let resourcesURL = Bundle.testBundle.resourceURL!
        return [
            ConfigLoader.userInfoVerboseKey: true,
            ConfigLoader.userInfoDirectoryKey: resourcesURL,
            ConfigLoader.userInfoFilenameKey: "HTTPEndpointTests",
        ]
    }
}
