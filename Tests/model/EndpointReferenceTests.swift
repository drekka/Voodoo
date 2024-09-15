//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation
import Nimble
@testable import Voodoo
import XCTest
import Yams

class EndPointReferenceTests: XCTestCase {

    func testDecodeHTTPEndpoint() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        http:
          api: get /abc
        response:
          status: 200
        """#
        let endpoint = try decoder.decode(EndpointReference.self, from: yml)
        expect(endpoint.endpoints.count) == 1
        let httpEndpoint = endpoint.endpoints[0] as! HTTPEndpoint
        expect(httpEndpoint.method) == .GET
        expect(httpEndpoint.path) == "/abc"
        expect(httpEndpoint.response) == .ok()
    }

    func testDecodeGraphQLEndpoint() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        graphQL:
          method: get
          operations: abc
        response:
          status: 200
        """#
        let endpoint = try decoder.decode(EndpointReference.self, from: yml)
        expect(endpoint.endpoints.count) == 1
        let graphQLEndpoint = endpoint.endpoints[0] as! GraphQLEndpoint
        expect(graphQLEndpoint.method) == .GET
        expect(graphQLEndpoint.selector) == .operations("abc")
        expect(graphQLEndpoint.response) == .ok()
    }

    func testDecodeFileReference() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        files/TestConfig1/get-config.yml
        """#

        let endpoint = try decoder.decode(EndpointReference.self, from: yml, userInfo: [ConfigLoader.userInfoDirectoryKey: Bundle.testBundle])
        expect(endpoint.endpoints.count) == 1
        let httpEndpoint = endpoint.endpoints[0] as! HTTPEndpoint
        expect(httpEndpoint.method) == .GET
        expect(httpEndpoint.path) == "/config"
        expect(httpEndpoint.response) == .ok(body: .json(["version": 1.0]))
    }

    func testDecodeFailure() throws {
        let decoder = YAMLDecoder()
        let yml = #"""
        xxx:
          yyyy: get
        """#
        do {
            _ = try decoder.decode(EndpointReference.self, from: yml)
        } catch DecodingError.dataCorrupted(let context) {
            guard let actualError = context.underlyingError as? VoodooError else {
                return
            }
            expect(actualError.debugDescription) == "Failure decoding end points in [Unknown]"
        }
    }
}
