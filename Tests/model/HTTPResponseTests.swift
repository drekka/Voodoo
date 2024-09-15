//
//  Created by Derek Clarkson on 19/9/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import Voodoo
import XCTest
import Yams

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
                         withHeaders: [HTTPHeader.contentType: HTTPHeader.ContentType.textPlain.contentType],
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
        try await assertConvenienceCase(HTTPResponse.ok, returning: .ok)
        try await assertConvenienceCase(HTTPResponse.created, returning: .created)
        try await assertConvenienceCase(HTTPResponse.accepted, returning: .accepted)
        try await assertConvenienceCase(HTTPResponse.badRequest, returning: .badRequest)
        try await assertConvenienceCase(HTTPResponse.unauthorised, returning: .unauthorized)
        try await assertConvenienceCase(HTTPResponse.forbidden, returning: .forbidden)
        try await assertConvenienceCase(HTTPResponse.internalServerError, returning: .internalServerError)
    }

    // MARK: - Supporting functions

    func assertConvenienceCase(_ enumInit: (Voodoo.HTTPHeaders, HTTPResponse.Body) -> HTTPResponse, returning expectedStatus: HTTPResponseStatus) async throws {
        let response = enumInit(testHeaders, .text("hello"))
        var expectedHeaders = testHeaders
        expectedHeaders[HTTPHeader.contentType] = HTTPHeader.ContentType.textPlain.contentType
        try await assert(response: response, returnsStatus: expectedStatus, withHeaders: expectedHeaders, body: "hello")
    }

    func assert(response: HTTPResponse,
                returnsStatus expectedStatus: HTTPResponseStatus,
                withHeaders expectedHeaders: Voodoo.HTTPHeaders = [:],
                body expectedBody: String? = nil) async throws {

        let request = HBRequest.mock().asHTTPRequest
        let context = MockVoodooContext()
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

        if let expectedBody {
            expect(hbResponse.body) == expectedBody.hbResponseBody
        } else {
            expect(hbResponse.body) == .empty
        }
    }
}

class HTTPResponseDecodableTests: XCTestCase {

    private let mockServer = "http://127.0.0.1:8080"

    func testDecodeFailsWhenInvalidContent() throws {
        try assert(#"""
                   xxxxxx: 200
                   """#,
                   failsOnPath: [], forKey: "status")
    }

    func testDecodeOk() throws {
        try assert(#"""
                   status: 200
                   """#,
                   decodesTo: .ok(body: .empty))
    }

    func testDecodeOkWithEmptyBody() throws {
        try assert(#"""
                   status: 200
                   body:
                   """#,
                   decodesTo: .ok(body: .empty))
    }

    func testDecodeOkWithBody() throws {
        try assert(#"""
                   status: 200
                   body:
                     text: Hello
                   """#,
                   decodesTo: .ok(body: .text("Hello")))
    }

    func testDecodeCreated() throws {
        try assert(#"""
                   status: 201
                   """#,
                   decodesTo: .created())
    }

    func testDecodeAccepted() throws {
        try assert(#"""
                   status: 202
                   """#,
                   decodesTo: .accepted())
    }

    func testDecodeMovedPermanenty() throws {
        try assert(#"""
                   status: 301
                   url: \#(mockServer)
                   """#,
                   decodesTo: .movedPermanently(mockServer))
    }

    func testDecodeTemporaryRedirect() throws {
        try assert(#"""
                   status: 307
                   url: \#(mockServer)
                   """#,
                   decodesTo: .temporaryRedirect(mockServer))
    }

    func testDecodePermanentRedirect() throws {
        try assert(#"""
                   status: 308
                   url: \#(mockServer)
                   """#,
                   decodesTo: .permanentRedirect(mockServer))
    }

    func testDecodeBadRequest() throws {
        try assert(#"""
                   status: 400
                   """#,
                   decodesTo: .badRequest())
    }

    func testDecodeUnauthorised() throws {
        try assert(#"""
                   status: 401
                   """#,
                   decodesTo: .unauthorised())
    }

    func testDecodeForbidden() throws {
        try assert(#"""
                   status: 403
                   """#,
                   decodesTo: .forbidden())
    }

    func testDecodeNotFound() throws {
        try assert(#"""
                   status: 404
                   """#,
                   decodesTo: .notFound)
    }

    func testDecodeNotAcceptable() throws {
        try assert(#"""
                   status : 406
                   """#,
                   decodesTo: .notAcceptable)
    }

    func testDecodeTooManyRequests() throws {
        try assert(#"""
                   status : 429
                   """#,
                   decodesTo: .tooManyRequests)
    }

    func testDecodeInternalServerError() throws {
        try assert(#"""
                   status: 500
                   """#,
                   decodesTo: .internalServerError())
    }

    func testDecodeOther() throws {
        try assert(#"""
                   status: 999
                   """#,
                   decodesTo: .raw(.custom(code: 999, reasonPhrase: "")))
    }

    // MARK: - Helpers

    func assert(_ yml: String,
                failsOnPath expectedPath: [String],
                forKey expectedKey: String,
                file: FileString = #file, line: UInt = #line) throws {
        do {
            _ = try YAMLDecoder().decode(HTTPResponse.self, from: yml.data(using: .utf8)!)
            fail("Expected error not thrown")
        } catch DecodingError.keyNotFound(let key, let context) {
            expect(file: file, line: line, key.stringValue) == expectedKey
            expect(file: file, line: line, context.codingPath.map(\.stringValue)) == expectedPath
        }
    }

    func assert(_ yml: String, decodesTo expectedResponse: HTTPResponse, file: FileString = #file, line: UInt = #line) throws {
        let response = try YAMLDecoder().decode(HTTPResponse.self, from: yml.data(using: .utf8)!)
        expect(file: file, line: line, response) == expectedResponse
    }
}
