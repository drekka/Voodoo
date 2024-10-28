//
//  Created by Derek Clarkson on 11/10/21.
//

import Hummingbird
import Nimble
import NIOHTTP1
import Voodoo
import XCTest

class IntegrationJavascriptTests: XCTestCase, IntegrationTesting {

    var server: VoodooServer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = try VoodooServer()
    }

    override func tearDown() {
        tearDownServer()
        super.tearDown()
    }

    func testJavascriptResponseText() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            return Response.ok(Body.text("Hello world!"));
        }
        """#))

        let response = await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        expect(String(data: response.data!, encoding: .utf8)) == "Hello world!"
        expect(response.response?.value(forHTTPHeaderField: Header.contentType)) == Header.ContentType.textPlain
    }

    func testJavascriptResponseEmptyDefault() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            return Response.ok();
        }
        """#))

        let response = await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        expect(response.data) == Data()
        expect(response.response?.value(forHTTPHeaderField: Header.contentType)).to(beNil())
    }

    func testJavascriptNoFunction() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        """#))

        let response = await executeAPICall(.GET, "/abc", andExpectStatusCode: 500)
        expect(String(data: response.data!, encoding: .utf8)) == "The executed javascript does not contain a function with the signature 'response(request, cache)'."
    }

    func testJavascriptIncorrectSignatureArgumentsTooFew() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response() {
            return Response.ok();
        }
        """#))

        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
    }

    func testJavascriptIncorrectSignatureArgumentsTooMany() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(a,b,c,d,e) {
            return Response.ok();
        }
        """#))

        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
    }

    func testJavascriptInvalidResponse() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            return;
        }
        """#))

        let response = await executeAPICall(.GET, "/abc", andExpectStatusCode: 500)
        expect(String(data: response.data!, encoding: .utf8)) == "The javascript function failed to return a response."
    }

    func testJavascriptResponseSetAndGetFromCache() async {

        server.add(.POST, "/abc", response: .javascript(#"""
        function response(request, cache) {
            cache.abc = "Hello world!";
            return Response.ok();
        }
        """#))

        await executeAPICall(.POST, "/abc", andExpectStatusCode: 200)

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            var abc = cache.abc;
            return Response.ok(Body.text(abc));
        }
        """#))

        let response = await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        let httpResponse = response.response

        expect(String(data: response.data!, encoding: .utf8)) == "Hello world!"
        expect(httpResponse?.value(forHTTPHeaderField: Header.contentType)) == Header.ContentType.textPlain
    }
}
