//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation
import Nimble
import NIOHTTP1
@testable import Voodoo
import XCTest
import Yams

class HTTPEndpointTests: XCTestCase {

    func testInitWithArgs() {
        let endpoint = HTTPEndpoint(.GET, "/abc")
        expect(endpoint.method) == .GET
        expect(endpoint.path) == "/abc"
        expect(endpoint.response) == .ok()
    }

    func testCanDecode() throws {

        let goodHttp = "http: ~"
        let badHttp = "xxx: ~"

        struct Container: Decodable {
            let canDecode: Bool
            init(from decoder: Decoder) throws {
                canDecode = try HTTPEndpoint.canDecode(from: decoder)
            }
        }

        let container1 = try YAMLDecoder().decode(Container.self, from: goodHttp)
        expect(container1.canDecode) == true
        let container2 = try YAMLDecoder().decode(Container.self, from: badHttp)
        expect(container2.canDecode) == false
    }


    func testDecodeWithResponse() throws {
        let yaml = #"""
        http:
          api: "post /abc"
        response:
          status: 200
        """#

        let endpoint = try YAMLDecoder().decode(HTTPEndpoint.self, from: yaml, userInfo: userInfo())

        expect(endpoint.method) == .POST
        expect(endpoint.path) == "/abc"
        expect(endpoint.response) == .ok()
    }

    func testDecodeWithInvalidSignature() throws {
        try expectYML(#"""
                      http:
                        api: "post/abc"
                      response: "ok"
                      """#,
                      toFailWithDataCorrupt: "Incorrect 'api' value. Expected <method> <path>")
    }

    func testDecodeWithNoResponse() throws {
        try expectYML(#"""
                      http:
                        api: "get post/abc"
                      """#,
                      toFailWithDataCorrupt: "Expected to find 'response', 'javascript' or 'javascriptFile'")
    }

    // MARK: - Support

    private func expectYML(file: StaticString = #file, line: UInt = #line, _ yml: String, toFailWithTypeMissMatch expectedMessage: String) throws {
        do {
            _ = try YAMLDecoder().decode(HTTPEndpoint.self, from: yml, userInfo: userInfo())
            fail("Error not thrown", file: file, line: line)
        } catch {
            guard case DecodingError.typeMismatch(_, let context) = error else {
                fail("Incorrect exception \(error)", file: file, line: line)
                return
            }
            expect(file: file, line: line, context.debugDescription) == expectedMessage
        }
    }

    private func expectYML(file: StaticString = #file, line: UInt = #line, _ yml: String, toFailWithDataCorrupt expectedMessage: String) throws {
        do {
            _ = try YAMLDecoder().decode(HTTPEndpoint.self, from: yml, userInfo: userInfo())
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
