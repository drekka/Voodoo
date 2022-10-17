//
//  File.swift
//
//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation
import Nimble
import NIOHTTP1
@testable import SimulcraCore
import XCTest
import Yams

class EndpointTests: XCTestCase {

    func testInitWithArgs() {
        let endpoint = Endpoint(.GET, "/abc")
        expect(endpoint.method) == .GET
        expect(endpoint.path) == "/abc"
        expect(endpoint.response) == .ok()
    }

    func testDecode() throws {
        try expectYML(#"""
                      signature: "post /abc"
                      response:
                        status: 200
                      """#,
                      toDecodeAs: .POST, "/abc", response: .ok())
    }

    func testDecodeWithResponse() throws {
        try expectYML(#"""
                      signature: "post /abc"
                      response:
                        status: 200
                        headers:
                          abc: "123"
                        body:
                          type: "text"
                          text: "Hey everyone - {{def}}"
                          templateData:
                            def: "hello world!"
                      """#,
                      toDecodeAs: .POST, "/abc",
                      response: .ok(headers: ["abc": "123"],
                                    body: .text("Hey everyone - {{def}}",
                                                templateData: ["def": "Hello world!"])))
    }

    func testDecodeWithInvalidSignature() throws {
        try expectYML(#"""
                      signature: "post/abc"
                      response: "ok"
                      """#,
                      toFailWithDataCorrupt: "Incorrect signature. Expected <method> <path>")
    }

    func testDecodeWithEmbeddedJavascript() throws {
        try expectYML(#"""
                      signature: "post /abc"
                      javascript: |
                        function response(request, cache) {
                           return Response.ok()
                        }
                      """#,
                      toDecodeAs: .POST, "/abc",
                      response: .javascript("function response(request, cache) {\n   return Response.ok()\n}"))
    }

    func testDecodeWithExternalJavascript() throws {
        try expectYML(#"""
                      signature: "post /abc"
                      javascriptFile: Test files/TestConfig1/login.js
                      """#,
                      toDecodeAs: .POST, "/abc",
                      response: .javascript("function response(request, cache) {\n    return Response.ok()\n}\n"))
    }

    func testDecodeWithMissingExternalJavascript() throws {
        try expectYML(#"""
                      signature: "get post/abc"
                      javascriptFile: Test files/TestConfig1/xxx.js
                      """#) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                fail("Incorrect exception")
                return
            }
            expect((context).debugDescription).to(beginWith("Unable to find referenced javascript file"))
            expect((context).debugDescription).to(endWith("Test files/TestConfig1/xxx.js'"))
        }
    }

    func testDecodeWithNoResponse() throws {
        try expectYML(#"""
                      signature: "get post/abc"
                      """#,
                      toFailWithDataCorrupt: "Expected to find 'response', 'javascript' or 'javascriptFile'")
    }

    // MARK: - Support

    private func expectYML(_ yml: String,
                           toDecodeAs expectedMethod: HTTPMethod,
                           _ expectedPath: String,
                           response expectedResponse: HTTPResponse) throws {
        let endpoint = try YAMLDecoder().decode(Endpoint.self, from: yml, userInfo: userInfo())

        expect(endpoint.method) == expectedMethod
        expect(endpoint.path) == expectedPath
        expect(endpoint.response) == expectedResponse
    }

    private func expectYML(_ yml: String, toFailWithDataCorrupt expectedMessage: String) throws {
        try expectYML(yml) {
            guard case DecodingError.dataCorrupted(let context) = $0 else {
                fail("Incorrect exception")
                return
            }
            expect(context.debugDescription) == expectedMessage
        }
    }

    private func expectYML(_ yml: String, toFail errorValidation: (Error) -> Void) throws {
        do {
            _ = try YAMLDecoder().decode(Endpoint.self, from: yml, userInfo: userInfo())
            fail("Error not thrown")
        } catch {
            errorValidation(error)
        }
    }

    private func userInfo() -> [CodingUserInfoKey: Any] {
        let resourcesURL = Bundle.testBundle.resourceURL!
        return [
            ConfigLoader.userInfoVerboseKey: true,
            ConfigLoader.userInfoDirectoryKey: resourcesURL,
        ]
    }
}
