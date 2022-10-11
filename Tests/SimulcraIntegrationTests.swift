//
//  Created by Derek Clarkson on 11/10/21.
//

import Hummingbird
import Nimble
import NIOHTTP1
import SimulcraCore
import XCTest

class SimulcraIntegrationTests: XCTestCase, IntegrationTesting {

    var server: Simulcra!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setUpServer()
    }

    override func tearDown() {
        tearDownServer()
        super.tearDown()
    }

    // MARK: - Init

    func testInitWithMulitpleServers() throws {
        let s2 = try Simulcra()
        expect(s2.port) != server.port
    }

    func testInitRunsOutOfPorts() {
        let currentPort = server.port
        expect {
            try Simulcra(portRange: currentPort ... currentPort)
        }
        .to(throwError(SimulcraError.noPortAvailable))
    }

    func testInitWithEndpoints() async throws {
        server = try Simulcra {
            Endpoint(.GET, "/abc")
            Endpoint(.GET, "/def", response: .created())
        }
        await assert(.GET, "/abc", returns: .ok)
        await assert(.GET, "/def", returns: .created)
    }

    // MARK: - Adding APIs

    func testEndpointViaEndpointType() async {
        server.add(Endpoint(.GET, "/abc"))
        await assert(.GET, "/abc", returns: .ok)
    }

    func testEndpointsViaEndpointType() async {
        server.add([
            Endpoint(.GET, "/abc"),
            Endpoint(.GET, "/def", response: .created()),
        ])
        await assert(.GET, "/abc", returns: .ok)
        await assert(.GET, "/def", returns: .created)
    }

    func testEndpointWithDynamicClosure() async {
        server.add(.GET, "/abc", response: { _, _ in .ok() })
        await assert(.GET, "/abc", returns: .ok)
    }

    func testEndpointViaArguments() async {
        server.add(.GET, "/abc")
        await assert(.GET, "/abc", returns: .ok)
    }

    func testEndpointsBuilder() async {

        @EndpointBuilder
        func otherEndpoints(inc: Bool) -> [Endpoint] {
            if inc {
                Endpoint(.GET, "/aaa", response: .accepted())
            } else {
                Endpoint(.GET, "/bbb")
            }
        }

        server.add {
            Endpoint(.GET, "/abc")
            Endpoint(.GET, "/def", response: .created())
            otherEndpoints(inc: true)
            otherEndpoints(inc: false)
            if true {
                Endpoint(.GET, "/ccc")
            }
        }

        await assert(.GET, "/abc", returns: .ok)
        await assert(.GET, "/def", returns: .created)
        await assert(.GET, "/aaa", returns: .accepted)
        await assert(.GET, "/bbb", returns: .ok)
        await assert(.GET, "/ccc", returns: .ok)
    }

    // MARK: - Swift responses

    func testResponse() async {
        server.add(.POST, "/abc", response: .accepted())
        await assert(.POST, "/abc", returns: .accepted)
    }

    func testResponseFromClosure() async {
        server.add(.POST, "/abc") { _, _ in
            .ok()
        }
        await assert(.POST, "/abc", returns: .ok)
    }

    func testResponseWithHeaders() async {

        server.add(.POST, "/abc", response: .accepted(headers: ["Token": "123"]))
        let response = await assert(.POST, "/abc", returns: .accepted)

        expect(response.response?.allHeaderFields.count) == 5
        expect(response.response?.value(forHTTPHeaderField: "token")) == "123"
        expect(response.response?.value(forHTTPHeaderField: "server")) == "Simulcra API simulator"
    }

    func testResponseWithBody() async {

        server.add(.POST, "/abc", response: .accepted(headers: ["Token": "123"], body: .text("Hello")))
        let response = await assert(.POST, "/abc", returns: .accepted)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 6
        expect(String(data: response.data!, encoding: .utf8)) == "Hello"
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
    }

    func testResponseWithInlineTemplate() async {

        server.add(.POST, "/abc", response: .accepted(body: .text("Hello {{name}}", templateData: ["name": "Derek"])))
        let response = await assert(.POST, "/abc", returns: .accepted)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 5
        expect(String(data: response.data!, encoding: .utf8)) == "Hello Derek"
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
    }

    func testResponseWithFileTemplate() async {

        server.add(.POST, "/abc", response: .accepted(body: .template("Template", templateData: ["path": "/abc"])))
        let response = await assert(.POST, "/abc", returns: .accepted)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 5
        expect(String(data: response.data!, encoding: .utf8)) == #"{\#n    "url": "\#(HBRequest.mockHost):\#(server.port)",\#n    "path": "/abc"\#n}\#n"#
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.applicationJSON
    }

    func testResponsePassingCacheData() async {
        server.add(.POST, "/abc") { _, cache in
            cache.abc = "123"
            return .ok()
        }
        await assert(.POST, "/abc", returns: .ok)

        server.add(.GET, "/def") { _, cache in
            .ok(headers: ["def": cache.abc as String? ?? ""])
        }
        let response = await assert(.GET, "/def", returns: .ok)
        expect(response.response?.value(forHTTPHeaderField: "def")) == "123"
    }

    // MARK: - Javascript responses

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
            cache.set("abc", "Hello world!");
            return Response.ok();
        }
        """#))

        await assert(.POST, "/abc", returns: .ok)

        server.add(.GET, "/abc", response: .javascript(#"""
        function response(request, cache) {
            var abc = cache.get("abc");
            return Response.ok(Body.text(abc));
        }
        """#))

        let response = await assert(.GET, "/abc", returns: .ok)
        let httpResponse = response.response

        expect(String(data: response.data!, encoding: .utf8)) == "Hello world!"
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
    }

    // MARK: - Middleware

    func testNoResponseFoundMiddleware() async {
        await assert(.GET, "/abc", returns: .notFound)
    }
}
