//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation
import Nimble
import NIOHTTP1
@testable import Voodoo
import XCTest
import Yams

struct DummyEndPoint: Decodable {

    let response: HTTPResponse

    public init(from decoder: Decoder) throws {
        response = try decoder.decodeResponse()
    }
}

class ResponseDecodingTests: XCTestCase {

    func testDecodeFixedSimple() throws {
        try expectYML(#"""
                      response:
                        status: 200
                      """#,
                      toDecodeAsResponse: .ok())
    }

    func testDecodeWithInlineJavascript() throws {
        try expectYML(#"""
                      javascript: |
                        function response(request, cache) {
                           return Response.ok()
                        }
                      """#,
                      toDecodeAsResponse: .javascript("function response(request, cache) {\n   return Response.ok()\n}"))
    }

    func testDecodeWithJavascriptFile() throws {
        try expectYML(#"""
                      javascriptFile: files/TestConfig1/login.js
                      """#,
                      toDecodeAsResponse: .javascript("function response(request, cache) {\n    return Response.ok()\n}\n"))
    }

    func testDecodeWithMissingExternalJavascript() throws {
        try expectYML(#"""
        javascriptFile: files/TestConfig1/xxx.js
        """#) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                fail("Incorrect exception")
                return
            }
            expect(context.debugDescription).to(beginWith("Unable to find referenced javascript file"))
            expect(context.debugDescription).to(endWith("files/TestConfig1/xxx.js'"))
        }
    }

    func testDecodeWithNoResponse() throws {
        try expectYML(#"""
                      # Need a dummy value so the decoder sees this as valid YAML. Otherwise the test fails with an invalid format error.
                      a: 123
                      """#,
                      toFailWithDataCorrupt: "Expected to find 'response', 'javascript' or 'javascriptFile'")
    }

    // MARK: - Support

    private func expectYML(_ yml: String,
                           toDecodeAsResponse expectedResponse: HTTPResponse) throws {
        let endpoint = try YAMLDecoder().decode(DummyEndPoint.self, from: yml, userInfo: userInfo())

        expect(endpoint.response) == expectedResponse
    }

    private func expectYML(file: FileString = #file, line: UInt = #line, _ yml: String, toFailWithDataCorrupt expectedMessage: String) throws {
        try expectYML(yml) {
            guard case DecodingError.dataCorrupted(let context) = $0 else {
                fail("Incorrect exception, got \($0.localizedDescription)", file: file, line: line)
                return
            }
            expect(file: file, line: line, context.debugDescription) == expectedMessage
        }
    }

    private func expectYML(file: FileString = #file, line: UInt = #line,
                           _ yml: String,
                           toFail errorValidation: (Error) -> Void) throws {
        do {
            _ = try YAMLDecoder().decode(DummyEndPoint.self, from: yml, userInfo: userInfo())
            fail("Error not thrown", file: file, line: line)
        } catch {
            errorValidation(error)
        }
    }

    private func userInfo() -> [CodingUserInfoKey: Any] {
        let resourcesURL = Bundle.testBundle.resourceURL!
        return [
            ConfigLoader.userInfoVerboseKey: true,
            ConfigLoader.userInfoDirectoryKey: resourcesURL,
            ConfigLoader.userInfoFilenameKey: "ResponseDecodingTests",
        ]
    }
}
