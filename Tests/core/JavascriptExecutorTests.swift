//
//  Created by Derek Clarkson on 30/9/2022.
//

import AnyCodable
import Foundation
import Hummingbird
import Nimble
import NIOHTTP1
@testable import Voodoo
import XCTest
import PathKit

import JXKit

class JavascriptExecutorTests: XCTestCase {

    private let mockServer = "http://127.0.0.1:8080"

    // MARK: - Request details

    func testRequestDetailsMinimal() throws {

        let request = HBRequest.mock().asHTTPRequest
        try expectRequest(request, javascript: #"""
            console.log("Path components " + request.pathComponents);
            var data = {
                method: request.method,
                headers: request.headers,
                path: request.path,
                pathComponents: request.pathComponents,
                pathParameters: request.pathParameters,
                query: request.query,
                queryParameters: request.queryParameters,
                body: String.fromCharCode.apply(null, new Uint8Array(request.body))
            };
            return Response.ok(Body.json(data));
        """#) { results in

            expect(results["method"] as? String) == "GET"
            expect(results["path"] as? String) == "/abc"
            expect(results["pathComponents"] as? [String]) == ["abc"]

            let headers = results["headers"] as! [String: Any]
            expect(headers.count) == 1
            expect(headers["host"] as? String) == "127.0.0.1:8080"

            let pathParameters = results["pathParameters"] as! [String: Any]
            expect(pathParameters.count) == 0

            expect(results["query"] as? String) == nil
            let queryParameters = results["queryParameters"] as! [String: Any]
            expect(queryParameters.count) == 0

            expect(results["body"] as? String) == ""
        }
    }

    func testRequestDetails() throws {

        let request = HBRequest.mock(path: "/abc/def",
                                     pathParameters: ["pp1": "p123", "pp2": "p456"],
                                     query: "q1=q123&q2=q123&q1=q456",
                                     headers: ["h1": "hxyz", "h2": "h456"],
                                     body: "Hello world!")
        try expectRequest(request.asHTTPRequest, javascript: #"""
            console.log("Query parameters: " + request.queryParameters.length);
            var data = {
                method: request.method,
                headers: request.headers,
                path: request.path,
                pathComponents: request.pathComponents,
                pathParameters: request.pathParameters,
                query: request.query,
                queryParameters: request.queryParameters,
                body: String.fromCharCode.apply(null, new Uint8Array(request.body))
            };
            return Response.ok(Body.json(data));
        """#) { results in

            expect(results["method"] as? String) == "GET"
            expect(results["path"] as? String) == "/abc/def"
            expect(results["pathComponents"] as? [String]) == ["abc", "def"]

            let headers = results["headers"] as! [String: Any]
            expect(headers["h1"] as? String) == "hxyz"
            expect(headers["h2"] as? String) == "h456"

            let pathParameters = results["pathParameters"] as! [String: Any]
            expect(pathParameters["pp1"] as? String) == "p123"
            expect(pathParameters["pp2"] as? String) == "p456"

            expect(results["query"] as? String) == "q1=q123&q2=q123&q1=q456"
            let queryParameters = results["queryParameters"] as! [String: Any]
            expect(queryParameters["q1"] as? [String]) == ["q123", "q456"]
            expect(queryParameters["q2"] as? String) == "q123"

            expect(results["body"] as? String) == "Hello world!"
        }
    }

    func testRequestFormParameters() throws {

        let request = HBRequest.mock(
            contentType: HTTPHeader.ContentType.applicationFormData,
            body: #"formField1=Hello%20world!"#
        )
        try expectRequest(request.asHTTPRequest, javascript: #"""
            var data = {
                formParameters: request.formParameters,
                formField1: request.formParameters.formField1
            };
            return Response.ok(Body.json(data));
        """#) { results in
            let formData = results["formParameters"] as! [String: Any]
            expect(formData.count) == 1
            expect(formData["formField1"] as? String) == "Hello world!"
            expect(results["formField1"] as? String) == "Hello world!"
        }
    }

    func testRequestBodyJSON() throws {

        let request = HBRequest.mock(
            contentType: HTTPHeader.ContentType.applicationJSON,
            body: #"{"abc":"def"}"#
        )
        try expectRequest(request.asHTTPRequest, javascript: #"""
            var data = {
                body: request.bodyJSON
            };
            return Response.ok(Body.json(data));
        """#) { results in
            let body = results["body"] as! [String: Any]
            expect(body["abc"] as? String) == "def"
        }
    }

    private func expectRequest(_ request: HTTPRequest,
                               javascript: String,
                               toReturn validate: ([String: Any]) -> Void) throws {
        let executor = try JavascriptExecutor(serverContext: MockVoodooContext())
        let response = try executor.execute(script: #"""
                                                    function response(request, cache) {
                                                        \#(javascript)
                                                    }
                                            """#,
                                            for: request)
        guard case HTTPResponse.ok(_, let body) = response,
              case HTTPResponse.Body.json(let data, _) = body else {
            fail("Got unexpected response \(response)")
            return
        }

        validate(data as! [String: Any])
    }

    // MARK: - Raw Response

    func testResponseRawWithStatus() throws {
        try expectResponse(#"return Response.raw(201);"#, toReturn: .created())
    }

    func testResponseRawWithStatusBody() throws {
        try expectResponse(#"return Response.raw(201, Body.text("Hello"));"#, toReturn: .created(body: .text("Hello")))
    }

    func testResponseRawWithStatusTextBodyHeaders() throws {
        try expectResponse(#"return Response.raw(201, Body.text("Hello"), {abc:"123"});"#,
                           toReturn: .created(headers: ["abc": "123"], body: .text("Hello")))
    }

    func testResponseRawWithStatusJSONObjectBody() throws {
        try expectResponse(#"""
                           var obj = {
                                abc:"Hello world!"
                           }
                           return Response.raw(201, Body.json(obj));
                           """#,
                           toReturn: .created(body: .json(["abc": "Hello world!"])))
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
        try expectResponse(#"return Response.movedPermanently("\#(mockServer)");"#,
                           toReturn: .movedPermanently(mockServer))
    }

    func testResponseTemporaryRedirect() throws {
        try expectResponse(#"return Response.temporaryRedirect("\#(mockServer)");"#,
                           toReturn: .temporaryRedirect(mockServer))
    }

    func testResponsePermanendRedirect() throws {
        try expectResponse(#"return Response.permanentRedirect("\#(mockServer)");"#,
                           toReturn: .permanentRedirect(mockServer))
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
                           return Response.ok(Body.json({ abc: "Hello" }));
                           """#,
                           toReturn: .ok(body: .json(["abc": "Hello"])))
    }

    func testResponseBodyJSONWithTemplateData() throws {
        try expectResponse(#"""
                           return Response.ok(Body.json( { abc: "{{abc}}" }, { abc: "Hello" } ));
                           """#,
                           toReturn: .ok(body: .json(["abc": "{{abc}}"], templateData: ["abc": "Hello"])))
    }

    func testResponseBodyFile() throws {
        try expectResponse(#"return Response.ok(Body.file("/dir/file.dat", "text/plain"));"#,
                           toReturn: .ok(body: .file("/dir/file.dat", contentType: HTTPHeader.ContentType.textPlain)))
    }

    func testResponseBodyTemplate() throws {
        try expectResponse(#"return Response.ok(Body.template("template-name", "text/plain"));"#,
                           toReturn: .ok(body: .template("template-name", contentType: HTTPHeader.ContentType.textPlain)))
    }

    func testResponseBodyTemplateWithTemplateData() throws {
        try expectResponse(#"return Response.ok(Body.template("template-name", "text/plain", {abc: "Hello"}));"#,
                           toReturn: .ok(body: .template("template-name", templateData: ["abc": "Hello"], contentType: HTTPHeader.ContentType.textPlain)))
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
                       toThrowError: #"The javascript function returned an unexpected response. Make sure you are using the 'Response' object to generate a response. Returned error: typeMismatch(Swift.Dictionary<Swift.String, Any>, Swift.DecodingError.Context(codingPath: [], debugDescription: "Expected to decode Dictionary<String, Any> but found JXValue instead.", underlyingError: nil))"#)
    }

    func testFailureWhenInvalidResponseReturned() throws {
        expectResponse(#"""
                       throw "Error!!!!";
                       """#,
                       toThrowError: "Javascript execution failed. Error: Error!!!!")
    }

    func testFailureWithInvalidJavascript() throws {
        expectResponse(#"""
                       return Response.ok(Body.text("Hello"); // <- Missing bracket here.
                       """#,
                       toThrowError: "Error evaluating javascript: SyntaxError: Unexpected token ';'. Expected ')' to end an argument list.")
    }

    // MARK: - Headers

    func testHeaderAccessInJavascript() throws {
        try expectResponse(#"""
                           let abc = request.headers.abc;
                           console.log("abc: " + abc);
                           return Response.ok(Body.text(abc));
                           """#,
                           withHeaders: ["abc": "123"],
                           toReturn: .ok(body: .text("123")))
    }

    // MARK: - Cache

    func testUnconvertableValue() throws {

        struct NonCodable {}

        let cache = InMemoryCache()
        cache.abc = NonCodable()

        let context = JXContext()
        let keyArg = context.string("abc")
        let result = try cache.cacheGet(context: context, object: nil, args: [context.object(), keyArg])

        expect(result.isNull) == true
    }

    func testCacheMiss() throws {
        try expectResponse(#"""
                           return Response.ok(Body.text("Hello " + cache.abc));
                           """#,
                           toReturn: .ok(body: .text("Hello null")))
    }

    func testCacheString() throws {
        let mockContext = MockVoodooContext()
        try expectResponse(#"""
                           cache.abc = "Hello world!";
                           return Response.ok();
                           """#,
                           inContext: mockContext,
                           toReturn: .ok())
        try expectResponse(#"""
                           return Response.ok(Body.text(cache.abc));
                           """#,
                           inContext: mockContext,
                           toReturn: .ok(body: .text("Hello world!")))
    }

    func testCacheInt() throws {
        let mockContext = MockVoodooContext()
        try expectResponse(#"""
                           cache.abc = 123;
                           return Response.ok();
                           """#,
                           inContext: mockContext,
                           toReturn: .ok())
        try expectResponse(#"""
                           return Response.ok(Body.text(cache.abc.toString()));
                           """#,
                           inContext: mockContext,
                           toReturn: .ok(body: .text("123")))
    }

    func testCacheJSObject() throws {
        let mockContext = MockVoodooContext()
        try expectResponse(#"""
                           cache.abc = {
                               def: "Hello world!"
                           };
                           return Response.ok();
                           """#,
                           inContext: mockContext,
                           toReturn: .ok())
        try expectResponse(#"""
                           var abc = cache.abc;
                           return Response.ok(Body.text(abc.def));
                           """#,
                           inContext: mockContext,
                           toReturn: .ok(body: .text("Hello world!")))
    }

    func testCacheJSArray() throws {
        let mockContext = MockVoodooContext()
        try expectResponse(#"""
                           cache.abc = [
                           {
                               def: "Hello world!"
                           },
                           {
                               def: "Goodbye world!"
                           }
                           ];
                           return Response.ok();
                           """#,
                           inContext: mockContext,
                           toReturn: .ok())
        try expectResponse(#"""
                           var array = cache.abc;
                           return Response.ok(Body.text(array[0].def));
                           """#,
                           inContext: mockContext,
                           toReturn: .ok(body: .text("Hello world!")))
        try expectResponse(#"""
                           var array = cache.abc;
                           return Response.ok(Body.text(array[1].def));
                           """#,
                           inContext: mockContext,
                           toReturn: .ok(body: .text("Goodbye world!")))
    }

    // MARK: - Support

    private func expectResponse(_ response: String,
                                withHeaders headers: Voodoo.HTTPHeaders = [:],
                                inContext: VoodooContext = MockVoodooContext(),
                                toReturn expectedResponse: HTTPResponse) throws {
        let executor = try JavascriptExecutor(serverContext: inContext)
        let result = try executor.execute(script: #"""
            function response(request, cache) {
                \#(response)
            }
        """#, for: HBRequest.mock(headers: headers).asHTTPRequest)
        expect(result) == expectedResponse
    }

    private func expectResponse(file: FileString = #file, line: UInt = #line,
                                _ response: String,
                                toThrowError expectedMessage: String) {
        expectScript(file: file, line: line,
                     #"""
                     function response(request, cache) {
                         \#(response)
                     }
                     """#,
                     toThrowError: expectedMessage)
    }

    private func expectScript(file: FileString = #file, line: UInt = #line,
                              _ script: String,
                              inContext context: VoodooContext = MockVoodooContext(),
                              toThrowError expectedMessage: String) {
        do {
            let executor = try JavascriptExecutor(serverContext: context)
            _ = try executor.execute(script: script, for: HBRequest.mock().asHTTPRequest)
            fail("Expected exception not thrown executing script", file: file, line: line)
        } catch {
            if case VoodooError.javascriptError(let message) = error {
                if message != expectedMessage {
                    fail("expected '\(expectedMessage)' got '\(message)'", file: file, line: line)
                }
                return
            }
            fail("Unexpected error executing script: \(error.localizedDescription)", file: file, line: line)
        }
    }
}
