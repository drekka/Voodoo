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

    func testExecuteWithRawResponse() throws {
        try expectScript(response: #"Response.raw(201)"#, toReturn: .created, expectedBody: .empty)
    }

    func testExecuteWithOkResponse() throws {
        try expectScript(response: #"Response.ok()"#, toReturn: .ok, expectedBody: .empty)
    }

    func testExecuteWithOkResponseWithTextBody() throws {
        try expectScript(response: #"Response.ok(Body.text("Hello"))"#, toReturn: .ok, expectedBody: .text("Hello"))
    }

    // MARK: - Errors

    func testExecuteWithMissingFunction() throws {
        expectScript(#"""
                     """#,
                     toFailWith: "The executed javascript does not contain a function with the signature 'response(request, cache)'.")
    }

    func testExecuteWithNoResponse() throws {
        expectScript(#"""
                     function response() {
                     }
                     """#,
                     toFailWith: "The javascript function failed to return a response.")
    }

    func testExecuteWithInvalidResponse() throws {
        expectScript(#"""
                     function response() {
                         return "abc";
                     }
                     """#,
                     toFailWith: #"The javascript function returned an invalid response. Make sure you are using the 'Response' object to generate a response. Returned error: The data couldn’t be read because it isn’t in the correct format."#)
    }

    func testExecuteInvalidJavascript() throws {
        expectScript(#"""
                     function response() {
                         return Response.ok(Body.text("Hello"); // <- Missing bracket here.
                     }
                     """#,
                     toFailWith: "Error evaluating javascript: SyntaxError: Unexpected token ';'. Expected ')' to end an argument list.")
    }

    // MARK: - Cache

    func testCacheString(file: StaticString = #file, line: UInt = #line) {
        expect(file: file, line: line, try self.execute(
            #"""
                function response(request, cache) {
                    cache.set("abc", "xyz");
                    return Response.ok(Body.text(cache.get("abc")));
                }
            """#
        ).statusCode) == HTTPResponseStatus.ok.code
    }

    // MARK: - Support

    func expectScript(file: StaticString = #file,
                      line: UInt = #line,
                      response: String,
                      toReturn expectedStatusCode: HTTPResponseStatus,
                      expectedBody: HTTPResponse.Body) throws {
        let result = try execute(#"""
            function response() {
                return \#(response);
            }
        """#)
        expect(file: file, line: line, result.statusCode) == expectedStatusCode.code
        expect(file: file, line: line, result.body) == expectedBody
    }

    private func expectScript(file: StaticString = #file, line: UInt = #line, _ script: String, toFailWith expectedMessage: String) {
        do {
            _ = try execute(script)
            fail("Exception not thrown", file: file, line: line)
        } catch {
            if case SimulcraError.javascriptError(let message) = error {
                if message != expectedMessage {
                    fail("expected '\(expectedMessage)' got '\(message)'", file: file, line: line)
                }
                return
            }
            fail("Unexpected error: \(error)", file: file, line: line)
        }
    }

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
