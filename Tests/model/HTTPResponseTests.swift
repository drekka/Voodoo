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
@testable import SimulacraCore
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
        function response(request, cache) {
            return Response.ok();
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
        var expectedHeaders = testHeaders
        expectedHeaders[ContentType.key] = ContentType.textPlain
        try await assert(response: response, returnsStatus: expectedStatus, withHeaders: expectedHeaders, body: "hello")
    }

    func assert(response: HTTPResponse,
                returnsStatus expectedStatus: HTTPResponseStatus,
                withHeaders expectedHeaders: [String: String]? = nil,
                body expectedBody: String? = nil) async throws {

        let request = HBRequest.mock().asHTTPRequest
        let context = MockSimulacraContext()
        let hbResponse = try await response.hbResponse(for: request, inServerContext: context)

        expect(hbResponse.status) == expectedStatus

        expect(hbResponse.headers.count) == expectedHeaders?.count ?? 0
        expectedHeaders?.forEach {
            guard let value = hbResponse.headers.first(name: $0) else {
                fail("Header '\($0) not found in response.")
                return
            }
            expect(value) == $1
        }

        if let expectedBody {
            expect(hbResponse.body) == expectedBody.hbResponseBody
        } else {
            expect(hbResponse.body) == .empty
        }
    }
}

class HTTPResponseDecodableTests: XCTestCase {

    private let mockServer = "http://127.0.0.1:8080"

    func testStatusAndJavascriptIsInvalid() throws {
        try assert(#"""
                   {
                       "status":200,
                       "javascript": "function response(request, cache) { return .ok(); }"
                   }
                   """#,
                   failsOnPath: ["javascript"], withError: "Cannot have both 'status' and 'javascript'.")
    }

    func testNoStatusOrJavahkscriptIsInvalid() throws {
        try assert(#"""
                   {
                   }
                   """#,
                   failsOnPath: ["status"], withError: "Response must container either 'status' or 'javascript'.")
    }

    func testDecodeJavascript() throws {
        try assert(#"""
                   {
                    "javascript": "function response(request, cache) { return .ok(); }"
                   }
                   """#,
                   decodesTo: .javascript(#"function response(request, cache) { return .ok(); }"#))
    }

    func testDecodeOk() throws {
        try assert(#"{"status":200}"#, decodesTo: .ok())
    }

    func testDecodeCreated() throws {
        try assert(#"{"status":201}"#, decodesTo: .created())
    }

    func testDecodeAccepted() throws {
        try assert(#"{"status":202}"#, decodesTo: .accepted())
    }

    func testDecodeMovedPermanenty() throws {
        try assert(#"{"status": 301,"url":"\#(mockServer)"}"#, decodesTo: .movedPermanently(mockServer))
    }

    func testDecodeTemporaryRedirect() throws {
        try assert(#"{"status": 307,"url":"\#(mockServer)"}"#, decodesTo: .temporaryRedirect(mockServer))
    }

    func testDecodeNotFound() throws {
        try assert(#"{"status":404}"#, decodesTo: .notFound)
    }

    func testDecodeNotAcceptable() throws {
        try assert(#"{"status":406}"#, decodesTo: .notAcceptable)
    }

    func testDecodeTooManyRequests() throws {
        try assert(#"{"status":429}"#, decodesTo: .tooManyRequests)
    }

    func testDecodeInternalServerError() throws {
        try assert(#"{"status":500}"#, decodesTo: .internalServerError())
    }

    // MARK: - Helpers

    func assert(_ json: String, failsOnPath expectedPath: [String], withError expectedError: String) throws {
        do {
            let data = json.data(using: .utf8)!
            _ = try JSONDecoder().decode(HTTPResponse.self, from: data)
            fail("Expected error not thrown")
        } catch DecodingError.dataCorrupted(let context) {
            expect(context.codingPath.map { $0.stringValue }) == expectedPath
            expect(context.debugDescription) == expectedError
        }
    }

    func assert(_ json: String, decodesTo expectedResponse: HTTPResponse) throws {
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(HTTPResponse.self, from: data)
        expect(response) == expectedResponse
    }
}
