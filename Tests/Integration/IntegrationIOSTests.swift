//
//  Created by Derek Clarkson on 11/10/21.
//

import Hummingbird
import Nimble
import NIOHTTP1
import Voodoo
import XCTest
import PathKit

class IntegrationIOSTests: XCTestCase, IntegrationTesting {

    var server: VoodooServer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = try VoodooServer(templatePath: Path(Bundle.testBundle.bundlePath))
    }

    override func tearDown() {
        tearDownServer()
        super.tearDown()
    }

    // MARK: - Adding APIs

    func testAddingEndpoint() async {
        server.add(HTTPEndpoint(.GET, "/abc"))
        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
    }

    func testAddingEndpointsViaArray() async throws {
        server.add([
            HTTPEndpoint(.GET, "/abc"),
            HTTPEndpoint(.GET, "/def", response: .created()),
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
                HTTPEndpoint(.GET, "/aaa", response: .accepted())
            } else {
                HTTPEndpoint(.GET, "/bbb")
            }
        }

        server.add {
            HTTPEndpoint(.GET, "/abc")
            HTTPEndpoint(.GET, "/def", response: .created())
            otherEndpoints(inc: true)
            otherEndpoints(inc: false)
            if true {
                HTTPEndpoint(.GET, "/ccc")
            }
        }

        await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/def", andExpectStatusCode: 201)
        await executeAPICall(.GET, "/aaa", andExpectStatusCode: 202)
        await executeAPICall(.GET, "/bbb", andExpectStatusCode: 200)
        await executeAPICall(.GET, "/ccc", andExpectStatusCode: 200)
    }

    // MARK: - Request details

    func testRequestJSONBody() async {

        server.add(.POST, "/abc") { request, _ in
            guard let body = request.bodyJSON as? [String: Any],
                  let bodyX = body["x"] as? Int,
                  bodyX == 123,
                  let bodyY = body["y"] as? String,
                  bodyY == "Hello" else {
                return .badRequest()
            }
            return .ok()
        }

        await executeAPICall(.POST, "/abc",
                             withHeaders: .init(contentType: .applicationJSON),
                             body: #"{"x":123, "y":"Hello"}"#.data(using: .utf8),
                             andExpectStatusCode: 200)
    }

    func testRequestDecodingJSONBody() async {

        struct Payload: Decodable {
            let x: Int
            let y: String
        }

        server.add(.POST, "/abc") { request, _ in
            guard let body = request.decodeBodyJSON(as: Payload.self),
                  body.x == 123,
                  body.y == "Hello" else {
                return .badRequest()
            }
            return .ok()
        }

        await executeAPICall(.POST, "/abc",
                             withHeaders: .init(contentType:.applicationJSON),
                             body: #"{"x":123, "y":"Hello"}"#.data(using: .utf8),
                             andExpectStatusCode: 200)
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
        expect(httpResponse?.value(forHTTPHeaderField: "content-type")) == "text/plain"
        expect(httpResponse?.value(forHTTPHeaderField: "abc")) == "def"
        expect(httpResponse?.value(forHTTPHeaderField: "server")) == "Voodoo API simulator"
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
    }

    // MARK: - Convenience responses

    func testResponseAccepted() async {
        await expectResponse(HTTPResponse.accepted(), toReturnStatus: 202)
    }

    func testResponseCreated() async {
        await expectResponse(HTTPResponse.created(), toReturnStatus: 201)
    }

    func testResponseMovedPermanently() async {
        await expectRedirectResponse(HTTPResponse.movedPermanently, toReturnStatus: 301)
    }

    func testResponseTemporaryRedirect() async {
        await expectRedirectResponse(HTTPResponse.temporaryRedirect, toReturnStatus: 307)
    }

    func testResponsePermanentRedirect() async {
        await expectRedirectResponse(HTTPResponse.permanentRedirect, toReturnStatus: 308)
    }

    func testResponseBadRequest() async {
        await expectResponse(HTTPResponse.badRequest(), toReturnStatus: 400)
    }

    func testResponseNotFound() async {
        await expectResponse(HTTPResponse.notFound, toReturnStatus: 404)
    }

    func testResponseNotAcceptable() async {
        await expectResponse(HTTPResponse.notAcceptable, toReturnStatus: 406)
    }

    func testResponseTooManyRequests() async {
        await expectResponse(HTTPResponse.tooManyRequests, toReturnStatus: 429)
    }

    func testResponseInternalServerError() async {
        await expectResponse(HTTPResponse.internalServerError(), toReturnStatus: 500)
    }

    // Case testing functions.

    func expectResponse(file: FileString = #file, line: UInt = #line, _ response: HTTPResponse, toReturnStatus expectedStatus: Int) async {
        server.add(.POST, "/abc", response: response)
        let result = await executeAPICall(.POST, "/abc", andExpectStatusCode: expectedStatus, file: file, line: line)
        expect(file: file, line: line, String(data: result.data!, encoding: .utf8)).to(equal(""), description: "Expected an empty response body,")
    }

    func expectRedirectResponse(file: FileString = #file, line: UInt = #line, _ response: (String) -> HTTPResponse, toReturnStatus expectedStatus: Int) async {
        server.add(.POST, "/abc", response: response("http://abc.com"))
        let result = await executeAPICall(.POST, "/abc", andExpectStatusCode: expectedStatus, file: file, line: line)
        expect(file: file, line: line, String(data: result.data!, encoding: .utf8)).to(equal(""), description: "Expected an empty response body,")
        expect(file: file, line: line, result.response?.value(forHTTPHeaderField: "location")).to(equal("http://abc.com"), description: "Expected a location header of 'http://abc.com',")
    }

    // MARK: - Bodies

    func testResponseWithBody() async {

        server.add(.POST, "/abc", response: .accepted(headers: ["Token": "123"], body: .text("Hello")))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 202)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 6
        expect(String(data: response.data!, encoding: .utf8)) == "Hello"
        expect(httpResponse?.value(forHTTPHeaderField: "content-type")) == "text/plain"
    }

    func testResponseWithInlineTextTemplate() async {

        server.add(.POST, "/abc", response: .accepted(body: .text("Hello {{name}}", templateData: ["name": "Derek"])))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 202)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 5
        expect(String(data: response.data!, encoding: .utf8)) == "Hello Derek"
        expect(httpResponse?.value(forHTTPHeaderField: "content-type")) == "text/plain"
    }

    func testResponseWithInlineJSONTemplate() async {

        server.add(.POST, "/abc", response: .ok(body: .json(["abc": "def {{name}}"], templateData: ["name": "Derek"])))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 200)
        let httpResponse = response.response

        expect(String(data: response.data!, encoding: .utf8)) == #"{"abc":"def Derek"}"#
        expect(httpResponse?.allHeaderFields.count) == 5
        expect(httpResponse?.value(forHTTPHeaderField: "content-type")) == "application/json"
    }

    func testResponseWithFileTemplate() async {

        server.add(.POST, "/abc", response: .accepted(body: .template("files/Template", templateData: ["path": "/abc"])))
        let response = await executeAPICall(.POST, "/abc", andExpectStatusCode: 202)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 5
        expect(String(data: response.data!, encoding: .utf8)) == #"{\#n    "url": "\#(server.url.host!):\#(server.url.port!)",\#n    "path": "/abc"\#n}\#n"#
        expect(httpResponse?.value(forHTTPHeaderField: "content-type")) == "application/json"
    }
}
