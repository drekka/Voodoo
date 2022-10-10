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

    // MARK: - Raw Response

    func testResponseRawWithStatusCode() throws {
        try expectResponse(#"return Response.raw(201);"#, toReturn: .created())
    }

    func testResponseRawWithStatusCodeBody() throws {
        try expectResponse(#"return Response.raw(201, Body.text("Hello"));"#, toReturn: .created(body: .text("Hello")))
    }

    func testResponseRawWithStatusCodeTextBodyHeaders() throws {
        try expectResponse(#"return Response.raw(201, Body.text("Hello"), {abc:"123"});"#,
                           toReturn: .created(headers: ["abc": "123"], body: .text("Hello")))
    }

    func testResponseRawWithStatusCodeJSONStringBody() throws {
        try expectResponse(#"""
                           var obj = {
                                abc:"Hello world!"
                           }
                           return Response.raw(201, Body.json(JSON.stringify(obj)));
                           """#,
                           toReturn: .created(body: .json(#"{"abc":"Hello world!"}"#)))
    }

    func testResponseRawWithStatusCodeJSONObjectBody() throws {
        try expectResponse(#"""
                           var obj = {
                                abc:"Hello world!"
                           }
                           return Response.raw(201, Body.json(obj));
                           """#,
                           toReturn: .created(body: .json(#"{"abc":"Hello world!"}"#)))
    }

    // MARK: - Other responses

    func testResponseOk() throws {
        try expectResponse(#"return Response.ok();"#, toReturn: .ok())
    }

    func testResponseOkWithBody() throws {
        try expectResponse(#"return Response.ok( Body.text("Hello"));"#, toReturn: .ok(body: .text("Hello")))
    }

    func testResponseOkWithBodyHeaders() throws {
        try expectResponse(#"return Response.ok( Body.text("Hello"), {"abc": "123"});"#,
                           toReturn: .ok(headers: ["abc": "123"], body: .text("Hello")))
    }

    func testResponseCreated() throws {
        try expectResponse(#"return Response.created();"#, toReturn: .created())
    }

    func testResponseCreatedWithBody() throws {
        try expectResponse(#"return Response.created( Body.text("Hello"));"#, toReturn: .created(body: .text("Hello")))
    }

    func testResponseCreatedWithBodyHeaders() throws {
        try expectResponse(#"return Response.created( Body.text("Hello"), {"abc": "123"});"#,
                           toReturn: .created(headers: ["abc": "123"], body: .text("Hello")))
    }

    func testResponseAccepted() throws {
        try expectResponse(#"return Response.accepted();"#, toReturn: .accepted())
    }

    func testResponseAcceptedWithBody() throws {
        try expectResponse(#"return Response.accepted( Body.text("Hello"));"#, toReturn: .accepted(body: .text("Hello")))
    }

    func testResponseAcceptedWithBodyHeaders() throws {
        try expectResponse(#"return Response.accepted( Body.text("Hello"), {"abc": "123"});"#,
                           toReturn: .accepted(headers: ["abc": "123"], body: .text("Hello")))
    }

    func testResponseMovedPermanently() throws {
        try expectResponse(#"return Response.movedPermanently("http://127.0.0.1/abc");"#,
                           toReturn: .movedPermanently("http://127.0.0.1/abc"))
    }

    func testResponseTemporaryRedirect() throws {
        try expectResponse(#"return Response.temporaryRedirect("http://127.0.0.1/abc");"#,
                           toReturn: .temporaryRedirect("http://127.0.0.1/abc"))
    }

    func testResponseNotFound() throws {
        try expectResponse(#"return Response.notFound();"#, toReturn: .notFound)
    }

    func testResponseNotAcceptable() throws {
        try expectResponse(#"return Response.notAcceptable();"#, toReturn: .notAcceptable)
    }

    func testResponseTooManyRequests() throws {
        try expectResponse(#"return Response.tooManyRequests();"#, toReturn: .tooManyRequests)
    }

    func testResponseInternalServerError() throws {
        try expectResponse(#"return Response.internalServerError();"#, toReturn: .internalServerError())
    }

    func testResponseInternalServerErrorWithBody() throws {
        try expectResponse(#"return Response.internalServerError( Body.text("Hello"));"#,
                           toReturn: .internalServerError(body: .text("Hello")))
    }

    func testResponseInternalServerErrorWithBodyHeaders() throws {
        try expectResponse(#"return Response.internalServerError( Body.text("Hello"), {"abc": "123"});"#,
                           toReturn: .internalServerError(headers: ["abc": "123"], body: .text("Hello")))
    }

    // MARK: - Body

    func testResponseBodyEmpty() throws {
        try expectResponse(#"return Response.ok();"#, toReturn: .ok())
    }

    func testResponseBodyText() throws {
        try expectResponse(#"return Response.ok(Body.text("Hello"));"#, toReturn: .ok(body: .text("Hello")))
    }

    func testResponseBodyTextTemplateData() throws {
        try expectResponse(#"return Response.ok(Body.text("{{abc}}", {abc: "Hello"}));"#,
                           toReturn: .ok(body: .text("{{abc}}", templateData: ["abc": "Hello"])))
    }

    func testResponseBodyJSON() throws {
        try expectResponse(#"""
                           return Response.ok(Body.json({
                                abc: "Hello"
                           }));
                           """#,
                           toReturn: .ok(body: .json(#"{"abc":"Hello"}"#)))
    }

    func testResponseBodyJSONWithTemplateData() throws {
        try expectResponse(#"""
                           return Response.ok(Body.json(
                           {
                                abc: "{{abc}}"
                           },{
                                abc: "Hello"
                           }
                           ));
                           """#,
                           toReturn: .ok(body: .json(#"{"abc":"{{abc}}"}"#, templateData: ["abc": "Hello"])))
    }

    func testResponseBodyFile() throws {
        try expectResponse(#"return Response.ok(Body.file("/dir/file.dat", "text/plain"));"#,
                           toReturn: .ok(body: .file(URL(fileURLWithPath: "/dir/file.dat"), contentType: "text/plain")))
    }

    func testResponseBodyTemplate() throws {
        try expectResponse(#"return Response.ok(Body.template("template-name", "text/plain"));"#,
                           toReturn: .ok(body: .template("template-name", contentType: "text/plain")))
    }

    func testResponseBodyTemplateWithTemplateData() throws {
        try expectResponse(#"return Response.ok(Body.template("template-name", "text/plain", {abc: "Hello"}));"#,
                           toReturn: .ok(body: .template("template-name", templateData: ["abc": "Hello"], contentType: "text/plain")))
    }

    // MARK: - Errors

    func testFailureWithMissingFunction() throws {
        expectScript("",
                     toThrowError: "The executed javascript does not contain a function with the signature 'response(request, cache)'.")
    }

    func testFailureWithNoResponse() throws {
        expectResponse("",
                       toThrowError: "The javascript function failed to return a response.")
    }

    func testFailureWithInvalidResponse() throws {
        expectResponse(#"""
                       return "abc";
                       """#,
                       toThrowError: #"The javascript function returned an invalid response. Make sure you are using the 'Response' object to generate a response. Returned error: typeMismatch(Swift.Dictionary<Swift.String, Any>, Swift.DecodingError.Context(codingPath: [], debugDescription: "Expected to decode Dictionary<String, Any> but found JXValue instead.", underlyingError: nil))"#)
    }

    func testFailureWithInvalidJavascript() throws {
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
                           toReturn: .ok(body: .text("Hello null")))
    }

    func testCacheString() throws {
        try expectResponse(#"""
                           cache.set("abc", "Hello world!");
                           return Response.ok();
                           """#,
                           toReturn: .ok())
        try expectResponse(#"""
                           return Response.ok(Body.text(cache.get("abc")));
                           """#,
                           toReturn: .ok(body: .text("Hello world!")))
    }

    func testCacheInt() throws {
        try expectResponse(#"""
                           cache.set("abc", 123);
                           return Response.ok();
                           """#,
                           toReturn: .ok())
        try expectResponse(#"""
                           return Response.ok(Body.text(cache.get("abc").toString()));
                           """#,
                           toReturn: .ok(body: .text("123")))
    }

    func testCacheJSObject() throws {
        try expectResponse(#"""
                           cache.set("abc", {
                               def: "Hello world!"
                           });
                           return Response.ok();
                           """#,
                           toReturn: .ok())
        try expectResponse(#"""
                           var abc = cache.get("abc");
                           return Response.ok(Body.text(abc.def));
                           """#,
                           toReturn: .ok(body: .text("Hello world!")))
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
                           toReturn: .ok())
        try expectResponse(#"""
                           var array = cache.get("abc");
                           return Response.ok(Body.text(array[0].def));
                           """#,
                           toReturn: .ok(body: .text("Hello world!")))
        try expectResponse(#"""
                           var array = cache.get("abc");
                           return Response.ok(Body.text(array[1].def));
                           """#,
                           toReturn: .ok(body: .text("Goodbye world!")))
    }

    // MARK: - Support

    private func expectResponse(_ response: String, toReturn expectedResponse: HTTPResponse) throws {
        let result = try execute(#"""
            function response(request, cache) {
                \#(response)
            }
        """#)
        expect(result) == expectedResponse
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
            fail("Expected exception not thrown executing script")
        } catch {
            if case SimulcraError.javascriptError(let message) = error {
                if message != expectedMessage {
                    fail("expected '\(expectedMessage)' got '\(message)'")
                }
                return
            }
            fail("Unexpected error executing script: \(error.localizedDescription)")
        }
    }

    @discardableResult
    private func execute(_ script: String) throws -> HTTPResponse {
        let request = MockRequest.create(url: "http://127.0.0.1:8080/abc")
        return try executor.execute(script: script, for: request)
    }
}
