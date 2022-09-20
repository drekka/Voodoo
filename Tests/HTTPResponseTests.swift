//
//  File.swift
//
//
//  Created by Derek Clarkson on 19/9/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import Simulcra
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

    func assertConvenienceCase(_ enumInit: (Headers, HTTPResponse.Body) -> HTTPResponse, returnsStatus expectedStatus: HTTPResponseStatus) async throws {
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
        let context = MockServerContext()
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
            let expectedBuffer = ByteBuffer(string: expectedBody)
            expect(hbResponse.body) == .byteBuffer(expectedBuffer)
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
            let lhsLength = lhsBuffer.readableBytes
            let lhsData = lhsBuffer.getData(at: 0, length: lhsLength)
            let rhsLength = rhsBuffer.readableBytes
            let rhsData = rhsBuffer.getData(at: 0, length: rhsLength)
            return lhsData == rhsData

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

    struct JSONTest: Codable {
        let abc: String
    }

    func testEmpty() throws {
        try assert(.empty, returns: nil, contentType: nil)
    }

    func testJSON() throws {
        try assert(.json(JSONTest(abc: "def")),
                   returns: #"{"abc":"def"}"#,
                   contentType: ContentType.applicationJSON)
    }

    func testJSONWithTemplateData() throws {
        try assert(.json(JSONTest(abc: #"def {{xyz}}"#), templateData: ["xyz": 123]),
                   returns: #"{"abc":"def 123"}"#,
                   contentType: ContentType.applicationJSON)
    }

    // MARK: - Support functions

    func assert(_ body: HTTPResponse.Body, returns expectedBody: String?, contentType expectedContentType: String?) throws {

        let context = MockServerContext()
        let hbBody = try body.hbBody(serverContext: context)

        if let expectedbody = expectedBody {
            let expectedBuffer = ByteBuffer(string: expectedbody)
            expect(hbBody.0) == .byteBuffer(expectedBuffer)
            expect(hbBody.1) == expectedContentType
        } else {
            expect(hbBody.0) == .empty
            expect(hbBody.1) == nil
        }
    }
}
