//
//  Created by Derek Clarkson on 11/10/21.
//

import Hummingbird
import Nimble
import NIOHTTP1
import SimulcraCore
import XCTest

class IntegrationJavascriptTests: XCTestCase, IntegrationTesting {

    var server: Simulcra!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setUpServer()
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

        let response = await assert(.GET, "/abc", returns: .ok)
        expect(String(data: response.data!, encoding: .utf8)) == "Hello world!"
        expect(response.response?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
    }

    func testJavascriptResponseEmptyDefault() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            return Response.ok();
        }
        """#))

        let response = await assert(.GET, "/abc", returns: .ok)
        expect(response.data) == Data()
        expect(response.response?.value(forHTTPHeaderField: ContentType.key)).to(beNil())
    }

    func testJavascriptNoFunction() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        """#))

        let response = await assert(.GET, "/abc", returns: .internalServerError)
        expect(response.response?.value(forHTTPHeaderField: SimulcraError.headerKey)) == "The executed javascript does not contain a function with the signature 'response(request, cache)'."
    }

    func testJavascriptIncorrectSignatureArgumentsTooFew() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response() {
            return Response.ok();
        }
        """#))

        await assert(.GET, "/abc", returns: .ok)
    }

    func testJavascriptIncorrectSignatureArgumentsTooMany() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(a,b,c,d,e) {
            return Response.ok();
        }
        """#))

        await assert(.GET, "/abc", returns: .ok)
    }

    func testJavascriptInvalidResponse() async {

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            return;
        }
        """#))

        let response = await assert(.GET, "/abc", returns: .internalServerError)
        expect(response.response?.value(forHTTPHeaderField: SimulcraError.headerKey)) == "The javascript function failed to return a response."
    }

    func testJavascriptResponseSetAndGetFromCache() async {

        server.add(.POST, "/abc", response: .javascript(#"""
        function response(request, cache) {
            cache.abc = "Hello world!";
            return Response.ok();
        }
        """#))

        await assert(.POST, "/abc", returns: .ok)

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            var abc = cache.abc;
            return Response.ok(Body.text(abc));
        }
        """#))

        let response = await assert(.GET, "/abc", returns: .ok)
        let httpResponse = response.response

        expect(String(data: response.data!, encoding: .utf8)) == "Hello world!"
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
    }
}
