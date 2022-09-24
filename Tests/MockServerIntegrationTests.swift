//
//  Created by Derek Clarkson on 11/10/21.
//

import Nimble
import NIOHTTP1
import Simulcra
import XCTest

class MockServerIntegrationTests: XCTestCase {

    typealias ServerResponse = (data: Data?, response: HTTPURLResponse?, error: Error?)

    private var server: MockServer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = try MockServer()
    }

    override func tearDown() {
        // Make sure we stop the server to avoid chewing up ports.
        server.stop()
        super.tearDown()
    }

    // MARK: - Init

    func testInit() throws {
        expect(self.server.address.absoluteString).to(match(#"127\.0\.0\.1:\d\d\d\d"#))
    }

    func testInitWithMulitpleServers() throws {
        let s2 = try MockServer()
        expect(s2.address.port) != server.address.port
    }

    func testInitRunsOutOfPorts() {
        let currentPort = server.address.port!
        expect {
            try MockServer(portRange: currentPort ... currentPort)
        }
        .to(throwError(MockServerError.noPortAvailable))
    }

    func testInitWithEndpoints() async throws {
        server = try MockServer {
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

    // MARK: - Responses

    func testResponse() async {
        server.add(.POST, "/abc", response: .accepted())
        await assert(.POST, "/abc", returns: .accepted)
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
        expect(httpResponse?.value(forHTTPHeaderField: "content-type")) == "text/plain"
    }

    func testResponseWithTemplate() async {

        server.add(.POST, "/abc", response: .accepted(body: .text("Hello {{name}}", templateData: ["name": "Derek"])))
        let response = await assert(.POST, "/abc", returns: .accepted)
        let httpResponse = response.response

        expect(httpResponse?.allHeaderFields.count) == 5
        expect(String(data: response.data!, encoding: .utf8)) == "Hello Derek"
        expect(httpResponse?.value(forHTTPHeaderField: "content-type")) == "text/plain"
    }

    // MARK: - Cache

    func testPassingValuesBetweenRequests() async {
        server.add(.POST, "/send", response: .dynamic { _, cache in
            cache.value = 5
            return .ok()
        })
        var result: Int?
        server.add(.GET, "/value", response: .dynamic { _, cache in
            result = cache.value
            return .ok()
        })

        await assert(.POST, "/send", returns: .ok)
        await assert(.GET, "/value", returns: .ok)

        expect(result) == 5
    }

    // MARK: - Middleware

    func testNoResponseFoundMiddleware() async {
        await assert(.GET, "/abc", returns: .notFound)
    }

    // MARK: - Support functions

    @discardableResult
    private func assert(_ method: HTTPMethod = .GET, _ path: String, returns expectedStatus: HTTPResponseStatus) async -> ServerResponse {

        var request = URLRequest(url: server.address.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        let response = await getData(from: request)

        expect(response.response!.statusCode) == Int(expectedStatus.code)
        expect(response.error).to(beNil())

        return response
    }

    private func getData(from url: URL) async -> ServerResponse {
        await getData(from: URLRequest(url: url))
    }

    private func getData(from request: URLRequest) async -> ServerResponse {
        do {
            let response = try await URLSession.shared.data(for: request)
            return ServerResponse(data: response.0, response: response.1 as? HTTPURLResponse, error: nil)
        } catch {
            return ServerResponse(data: nil, response: nil, error: error)
        }
    }
}
