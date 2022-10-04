//
//  File.swift
//
//
//  Created by Derek Clarkson on 30/9/2022.
//

import Foundation
import Nimble
import NIOHTTP1
@testable import SimulcraCore
import XCTest

class JavascriptExecutorTests: XCTestCase {

    private var mockContext: MockSimulcraContext!
    private var executor: JavascriptExecutor!

    override func setUpWithError() throws {
        mockContext = MockSimulcraContext()
        executor = try JavascriptExecutor(forContext: mockContext)
    }

    // MARK: - Response

    func testExecuteRawResponseWithStatusCode() throws {
        try expectResponse(#"return Response.raw(201);"#, toReturn: .created)
    }

    func testExecuteRawResponseWithStatusCodeBody() throws {
        try expectResponse(#"return Response.raw(201, Body.text("Hello"));"#, toReturn: .created, withBody: .text("Hello"))
    }

    func testExecuteRawResponseWithStatusCodeBodyHeaders() throws {
        try expectResponse(#"return Response.raw(201, Body.text("Hello"), {abc:"123"});"#,
                           toReturn: .created,
                           withBody: .text("Hello"),
                           headers: ["abc": "123"])
    }

    func testExecuteOkResponse() throws {
        try expectResponse(#"return Response.ok();"#, toReturn: .ok)
    }

    func testExecuteOkResponseWithBody() throws {
        try expectResponse(#"return Response.ok( Body.text("Hello"));"#, toReturn: .ok, withBody: .text("Hello"))
    }

    func testExecuteOkResponseWithBodyHeaders() throws {
        try expectResponse(#"return Response.ok( Body.text("Hello"), {"abc": "123"});"#,
                           toReturn: .ok,
                           withBody: .text("Hello"),
                           headers: ["abc": "123"])
    }

    // MARK: - Body

    func testExecuteBodyEmpty() throws {
        try expectResponse(#"return Response.ok();"#, toReturn: .ok)
    }

    func testExecuteBodyText() throws {
        try expectResponse(#"return Response.ok(Body.text("Hello"));"#,
                           toReturn: .ok,
                           withBody: .text("Hello"))
    }

    // MARK: - Errors

    func testExecuteWithMissingFunction() throws {
        expectScript(#"""
                     """#,
                     toThrowError: "The executed javascript does not contain a function with the signature 'response(request, cache)'.")
    }

    func testExecuteWithNoResponse() throws {
        expectResponse(#"""
                       """#,
                       toThrowError: "The javascript function failed to return a response.")
    }

    func testExecuteWithInvalidResponse() throws {
        expectResponse(#"""
                       return "abc";
                       """#,
                       toThrowError: #"The javascript function returned an invalid response. Make sure you are using the 'Response' object to generate a response. Returned error: typeMismatch(Swift.Dictionary<Swift.String, Any>, Swift.DecodingError.Context(codingPath: [], debugDescription: "Expected to decode Dictionary<String, Any> but found JXValue instead.", underlyingError: nil))"#)
    }

    func testExecuteInvalidJavascript() throws {
        expectResponse(#"""
                       return Response.ok(Body.text("Hello"); // <- Missing bracket here.
                       """#,
                       toThrowError: "Error evaluating javascript: SyntaxError: Unexpected token ';'. Expected ')' to end an argument list.")
    }

    // MARK: - Cache

    func testCacheMiss() throws {
        try expectResponse(#"""
                           return Response.ok(Body.text("Hello " + cache.get("abc")));
                           """#,
                           toReturn: .ok,
                           withBody: .text("Hello null"))
    }

    func testCacheString() throws {
        try expectResponse(#"""
                           cache.set("abc", "Hello world!");
                           return Response.ok();
                           """#,
                           toReturn: .ok)
        try expectResponse(#"""
                           return Response.ok(Body.text(cache.get("abc")));
                           """#,
                           toReturn: .ok,
                           withBody: .text("Hello world!"))
    }

    func testCacheInt() throws {
        try expectResponse(#"""
                           cache.set("abc", 123);
                           return Response.ok();
                           """#,
                           toReturn: .ok)
        try expectResponse(#"""
                           return Response.ok(Body.text(cache.get("abc").toString()));
                           """#,
                           toReturn: .ok,
                           withBody: .text("123"))
    }

    func testCacheJSObject() throws {
        try expectResponse(#"""
                           cache.set("abc", {
                               def: "Hello world!"
                           });
                           return Response.ok();
                           """#,
                           toReturn: .ok)
        try expectResponse(#"""
                           var abc = cache.get("abc");
                           return Response.ok(Body.text(abc.def));
                           """#,
                           toReturn: .ok,
                           withBody: .text("Hello world!"))
    }

    func testCacheJSArray() throws {
        try expectResponse(#"""
                           cache.set("abc", [
                           {
                               def: "Hello world!"
                           },
                           {
                               def: "Goodbye world!"
                           }
                           ]
                           );
                           return Response.ok();
                           """#,
                           toReturn: .ok)
        try expectResponse(#"""
                           var array = cache.get("abc");
                           return Response.ok(Body.text(array[0].def));
                           """#,
                           toReturn: .ok,
                           withBody: .text("Hello world!"))
        try expectResponse(#"""
                           var array = cache.get("abc");
                           return Response.ok(Body.text(array[1].def));
                           """#,
                           toReturn: .ok,
                           withBody: .text("Goodbye world!"))
    }

    // MARK: - Support

    private func expectResponse(_ response: String,
                                toReturn expectedStatusCode: HTTPResponseStatus,
                                withBody expectedBody: HTTPResponse.Body = .empty,
                                headers expectedHeaders: [String: String] = [:]) throws {
        let result = try execute(#"""
            function response(request, cache) {
                \#(response)
            }
        """#)
        expect(result.statusCode) == expectedStatusCode.code
        expect(result.body) == expectedBody
        expect(result.headers.count) == expectedHeaders.count
        expectedHeaders.forEach { expect(result.headers[$0]) == $1 }
    }

    private func expectResponse(_ response: String,
                                toThrowError expectedMessage: String) {
        expectScript(#"""
                     function response(request, cache) {
                         \#(response)
                     }
                     """#,
                     toThrowError: expectedMessage)
    }

    private func expectScript(_ script: String,
                              toThrowError expectedMessage: String) {
        do {
            try execute(script)
            fail("Expected exception not thrown")
        } catch {
            if case SimulcraError.javascriptError(let message) = error {
                if message != expectedMessage {
                    fail("expected '\(expectedMessage)' got '\(message)'")
                }
                return
            }
            fail("Unexpected error: \(error)")
        }
    }

    @discardableResult
    private func execute(_ script: String) throws -> JavascriptCallResponse {
        let request = MockRequest.create(url: "http://127.0.0.1:8080/abc")
        return try executor.execute(script: script, for: request)
    }
}

extension HTTPResponse.Body: Equatable {
    public static func == (lhs: SimulcraCore.HTTPResponse.Body, rhs: SimulcraCore.HTTPResponse.Body) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.template(let lhsName, _, _), .template(let rhsName, _, _)):
            return lhsName == rhsName
        case (.text(let lhsText, _), .text(let rhsText, _)):
            return lhsText == rhsText
        default:
            return false
        }
    }
}
