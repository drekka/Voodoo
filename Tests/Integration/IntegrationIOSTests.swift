//
//  Created by Derek Clarkson on 11/10/21.
//

import Hummingbird
import Nimble
import NIOHTTP1
import SimulacraCore
import XCTest

class IntegrationIOSTests: XCTestCase, IntegrationTesting {

    var server: Simulacra!

    override func setUpWithError() throws {
        try super.setUpWithError()
        try setUpServer()
    }

    override func tearDown() {
        tearDownServer()
        super.tearDown()
    }

    // MARK: - Init

    func testInitWithMultipleServers() throws {
        let s2 = try Simulacra()
        expect(s2.url.host) == server.url.host
        expect(s2.url.port) != server.url.port
    }

    func testInitRunsOutOfPorts() {
        let currentPort = server.url.port!
        expect {
            try Simulacra(portRange: currentPort ... currentPort)
        }
        .to(throwError(SimulacraError.noPortAvailable))
    }

    func testInitWithEndpoints() async throws {
        server = try Simulacra {
            Endpoint(.GET, "/abc")
            Endpoint(.GET, "/def", response: .created())
        }
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/def", andExpectStatusCode: 201)
    }

    // MARK: - File serving.

    func testFileServing() async throws {

        let resourcesURL = Bundle.testBundle.resourceURL!
        let filesURL = resourcesURL.appendingPathComponent("files")
        server = try Simulacra(filePaths: [filesURL])

        let response = await executeAPICall(.GET, "/Simple.html", andExpectStatusCode: 200)
        expect(String(data: response.data!, encoding: .utf8)) == "<html><body></body></html>\n"
        expect(response.response?.value(forHTTPHeaderField: "content-type")) == "text/html"
    }

    func testFileServingInvalidDirectory() async throws {

        let resourcesURL = Bundle.testBundle.resourceURL!
        let filesURL = resourcesURL.appendingPathComponent("XXXX")

        expect { try Simulacra(filePaths: [filesURL]) }.to(throwError { (error: Error) in
            guard case SimulacraError.directoryNotExists(let message) = error else {
                fail("Incorrect error \(error.localizedDescription)")
                return
            }
            expect(message).to(endWith("XXXX"))
        })
    }

    // MARK: - Adding APIs

    func testAddingEndpoint() async {
        server.add(Endpoint(.GET, "/abc"))
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
    }

    func testAddingEndpointsViaArray() async {
        server.add([
            Endpoint(.GET, "/abc"),
            Endpoint(.GET, "/def", response: .created()),
        ])
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/def", andExpectStatusCode: 201)
    }

    func testAddingEndpointViaIndividualArguments() async {
        server.add(.GET, "/abc")
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
    }

    func testAddingEndpointWithDynamicClosure() async {
        server.add(.GET, "/abc", response: { _, _ in .ok() })
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
    }

    func testAddingEndpointsViaBuilder() async {

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

        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/def", andExpectStatusCode: 201)
        await executeAPICall(.GET, "/aaa", andExpectStatusCode: 202)
        await executeAPICall(.GET, "/bbb", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/ccc", andExpectStatusCode: 200)
    }

    // MARK: - Core responses

    func testResponseRaw() async {
        server.add(.GET, "/abc", response: .raw(
            .accepted,
            headers: ["abc": "def"],
            body: .text(
                "Hello world! {{xyz}}",
                templateData: ["xyz": 123]
            )
        ))
        let response = await executeAPICall(.GET, "/abc", andExpectStatusCode: 202)

        let httpResponse = response.response

        expect(String(data: response.data!, encoding: .utf8)) == #"Hello world! 123"#

        expect(httpResponse?.allHeaderFields.count) == 6
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
        expect(httpResponse?.value(forHTTPHeaderField: "abc")) == "def"
        expect(httpResponse?.value(forHTTPHeaderField: "server")) == "Simulacra API simulator"
    }

    func testResponseDynamic() async {
        server.add(.POST, "/abc/:accountId",
                   response: .dynamic { request, _ in
                       .ok(headers: ["header1": request.headers.header1!],
                           body: .text("AccountID: {{account}}, search: {{searchTerms}}",
                                       templateData: [
                                           "account": request.pathParameters.accountId!,
                                           "searchTerms": request.queryParameters.search ?? "",
                                       ]))
                   })

        var request = URLRequest(url: URL(string: server.url.absoluteString + "/abc/1234?search=books")!)
        request.httpMethod = "POST"
        request.addValue("Hello world!", forHTTPHeaderField: "header1")

        let response = await executeAPICall(request, andExpectStatusCode: 200)
        expect(response.response?.value(forHTTPHeaderField: "header1")) == "Hello world!"
        expect(String(data: response.data!, encoding: .utf8)!) == "AccountID: 1234, search: books"
    }

    func testResponseDynamicViaFunction() async {
        server.add(.POST, "/abc") { _, _ in
            .ok()
        }
        await executeAPICall(.POST, "/abc", andExpectStatusCode: 200)
    }

    func testResponseDynamicPassingCacheDataBetweenRequests() async {
        server.add(.POST, "/abc") { _, cache in
            cache.abc = "Hello world!"
            cache.def = 123
            cache.xyz = [123, 456]
            return .ok()
        }
        await executeAPICall(.POST, "/abc", andExpectStatusCode: 200)

        server.add(.GET, "/def") { _, cache in
            .ok(headers: [
                "def": cache.abc as String? ?? "",
            ],
            body: .text("Count {{def}}, trailing: {{xyz}}", templateData: ["def": cache.def, "xyz": cache.xyz]))
        }
        let response = await executeAPICall(.GET, "/def", andExpectStatusCode: 200)
        expect(response.response?.value(forHTTPHeaderField: "def")) == "Hello world!"
        expect(response.response?.value(forHTTPHeaderField: "def")) == "Hello world!"
    }

    // MARK: - Convenience responses

    func testResponseAccepted() async {
        server.add(.POST, "/abc", response: .accepted())
        await executeAPICall(.POST, "/abc", andExpectStatusCode: 202)
    }

    // MARK: - Bodies

    func testResponseWithBody() async {

        server.add(.POST, "/abc", response: .accepted(headers: ["Token": "123"], body: .text("Hello")))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 202)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 6
        expect(String(data: response.data!, encoding: .utf8)) == "Hello"
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
    }

    func testResponseWithInlineTextTemplate() async {

        server.add(.POST, "/abc", response: .accepted(body: .text("Hello {{name}}", templateData: ["name": "Derek"])))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 202)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 5
        expect(String(data: response.data!, encoding: .utf8)) == "Hello Derek"
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.textPlain
    }

    func testResponseWithInlineJSONTemplate() async {

        server.add(.POST, "/abc", response: .ok(body: .json(["abc": "def {{name}}"], templateData: ["name": "Derek"])))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 200)
        let httpResponse = response.response

        expect(String(data: response.data!, encoding: .utf8)) == #"{"abc":"def Derek"}"#
        expect(httpResponse?.allHeaderFields.count) == 5
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.applicationJSON
    }

    func testResponseWithFileTemplate() async {

        server.add(.POST, "/abc", response: .accepted(body: .template("files/Template", templateData: ["path": "/abc"])))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 202)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 5
        expect(String(data: response.data!, encoding: .utf8)) == #"{\#n    "url": "\#(server.url.host!):\#(server.url.port!)",\#n    "path": "/abc"\#n}\#n"#
        expect(httpResponse?.value(forHTTPHeaderField: ContentType.key)) == ContentType.applicationJSON
    }

    // MARK: - Middleware

    func testNoResponseFoundMiddleware() async {
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 404)
    }
}
