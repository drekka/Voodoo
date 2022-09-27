//
//  File.swift
//
//
//  Created by Derek Clarkson on 19/9/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache
import Nimble
@testable import SimulcraCore
import XCTest

class HTTPResponseTests: XCTestCase {

    private let testHeaders = ["abc": "def"]

    // MARK: - Core

    func testRaw() async throws {
        try await assert(response: .raw(.ok), returnsStatus: .ok)
    }

    func testRawWithHeaders() async throws {
        let response = HTTPResponse.raw(.ok, headers: testHeaders)
        try await assert(response: response,
                         returnsStatus: .ok,
                         withHeaders: testHeaders)
    }

    func testRawWithTextBody() async throws {
        let response = HTTPResponse.raw(.ok, body: .text("hello"))
        try await assert(response: response,
                         returnsStatus: .ok,
                         withHeaders: [ContentType.key: ContentType.textPlain],
                         body: "hello")
    }

    func testDynamic() async throws {
        let response = HTTPResponse.dynamic { _, _ in
            .ok()
        }
        try await assert(response: response, returnsStatus: .ok)
    }

    func testJavascript() async throws {
        let response = HTTPResponse.javascript(#"""
        console.log("Hello");
        function response(request, cache) {
            return ok
        }
        """#)
        try await assert(response: response, returnsStatus: .ok)
    }

    // MARK: - Convenience cases

    func testConvenienceCasesWithBodies() async throws {
        try await assertConvenienceCase(HTTPResponse.ok, returnsStatus: .ok)
        try await assertConvenienceCase(HTTPResponse.created, returnsStatus: .created)
        try await assertConvenienceCase(HTTPResponse.accepted, returnsStatus: .accepted)
        try await assertConvenienceCase(HTTPResponse.badRequest, returnsStatus: .badRequest)
        try await assertConvenienceCase(HTTPResponse.unauthorised, returnsStatus: .unauthorized)
        try await assertConvenienceCase(HTTPResponse.forbidden, returnsStatus: .forbidden)
        try await assertConvenienceCase(HTTPResponse.internalServerError, returnsStatus: .internalServerError)
    }

    // MARK: - Supporting functions

    func assertConvenienceCase(_ enumInit: (HeaderDictionary, HTTPResponse.Body) -> HTTPResponse, returnsStatus expectedStatus: HTTPResponseStatus) async throws {
        let response = enumInit(testHeaders, .text("hello"))
        try await assert(response: response,
                         returnsStatus: expectedStatus,
                         withHeaders: testHeaders + [ContentType.key: ContentType.textPlain],
                         body: "hello")
    }

    func assert(response: HTTPResponse,
                returnsStatus expectedStatus: HTTPResponseStatus,
                withHeaders expectedHeaders: [String: String] = [:],
                body expectedBody: String? = nil) async throws {

        let request: HTTPRequest = MockRequest.create(url: "http://127.0.0.1")
        let context = MockMockServerContext()
        let hbResponse = try await response.hbResponse(for: request, inServerContext: context)

        expect(hbResponse.status) == expectedStatus

        expect(hbResponse.headers.count) == expectedHeaders.count
        expectedHeaders.forEach {
            guard let value = hbResponse.headers.first(name: $0) else {
                fail("Header '\($0) not found in response.")
                return
            }
            expect(value) == $1
        }

        if let expectedBody = expectedBody {
            expect(hbResponse.body) == expectedBody.hbResponseBody
        } else {
            expect(hbResponse.body) == .empty
        }
    }
}

extension HBResponseBody: Equatable {
    public static func == (lhs: HummingbirdCore.HBResponseBody, rhs: HummingbirdCore.HBResponseBody) -> Bool {
        switch (lhs, rhs) {

        case (.empty, .empty):
            return true

        case (.byteBuffer(let lhsBuffer), .byteBuffer(let rhsBuffer)):
            return lhsBuffer.data == rhsBuffer.data

        default:
            return false
        }
    }
}

extension Dictionary {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs) { $1 }
    }
}

class TestHTTPReponseBodyTests: XCTestCase {

    private var context: MockServerContext!

    override func setUp() {
        super.setUp()
        context = MockMockServerContext()
    }

    struct JSONTest: Codable {
        let abc: String
    }

    func testEmpty() throws {
        let context = MockMockServerContext()
        let hbBody = try HTTPResponse.Body.empty.hbBody(serverContext: context)
        expect(hbBody.0) == .empty
        expect(hbBody.1) == nil
    }

    func testJSON() throws {
        try assert(.json(JSONTest(abc: #"def {{xyz}}"#), templateData: ["xyz": 123]),
                   generates: #"{"abc":"def 123"}"#,
                   contentType: ContentType.applicationJSON)
    }

    func testData() throws {
        try assert(.data("abc".data(using: .utf8)!, contentType: ContentType.textPlain),
                   generates: "abc",
                   contentType: ContentType.textPlain)
    }

    func testText() throws {
        try assert(.text(#"def {{xyz}}"#, templateData: ["xyz": 123]),
                   generates: #"def 123"#,
                   contentType: ContentType.textPlain)
    }

    func testTemplate() throws {
        let template = try HBMustacheTemplate(string: "Hello {{xyz}}")
        context.mustacheRenderer.register(template, named: "fred")
        try assert(.template("fred", templateData: ["xyz": 123], contentType: ContentType.textPlain),
                   generates: #"Hello 123"#,
                   contentType: ContentType.textPlain)
    }

    func testFile() throws {
        let url = Bundle.testBundle.url(forResource: "Simple", withExtension: "html")!
        try assert(.file(url, contentType: ContentType.textHTML),
                   generates: #"<html><body></body></html>\#n"#,
                   contentType: ContentType.textHTML)
    }

    // MARK: - Support functions

    func assert(_ body: HTTPResponse.Body, generates expectedBody: String, contentType expectedContentType: String?) throws {
        let hbBody = try body.hbBody(serverContext: context)
        expect(hbBody.0) == expectedBody.hbResponseBody
        expect(hbBody.1) == expectedContentType
    }
}
