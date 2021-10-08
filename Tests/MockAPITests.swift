//
//  Created by Derek Clarkson on 7/10/21.
//

import Nimble
@testable import Simulcra
import Swifter
import XCTest

class MockAPITests: XCTestCase {

    var server: HttpServer!

    override func setUp() {
        super.setUp()
        server = HttpServer()
    }

    func testMockAPIRegistration() {
        validateRegister(.all) { self.server.routes }
        validateRegister(.get) { self.server.get.router.routes() }
        validateRegister(.put) { self.server.put.router.routes() }
        validateRegister(.delete) { self.server.delete.router.routes() }
        validateRegister(.post) { self.server.post.router.routes() }
    }

    func testMockAPIStackRegistration() {
        let mockAPI = MockAPIStack(method: .get,
                                   pathTemplate: "/abc",
                                   stack: [
                                       .ok(.text("not yet")),
                                       .internalServerError,
                                       .ok(.text("ok")),
                                   ])
        mockAPI.register(onServer: server) { _, _ in .internalServerError }
        expect(self.server.get.router.routes()[0]) == "/abc"
    }

    func testMockAPIStackRegistrationWithZeroResponsesNeverRegisters() {
        let mockAPI = MockAPIStack(method: .get,
                                   pathTemplate: "/abc",
                                   stack: [])
        mockAPI.register(onServer: server) { _, _ in .internalServerError }
        expect(self.server.get.router.routes().count) == 0
    }

    func testMockAPISStackQueuesResponses() {
        let mockAPI = MockAPIStack(method: .get,
                                   pathTemplate: "/abc",
                                   stack: [
                                       .ok(.text("not yet")),
                                       .internalServerError,
                                       .ok(.text("ok")),
                                   ])
        mockAPI.register(onServer: server) { _, _ in .internalServerError }
        let responseClosure = server.get.router.route("GET", path: "/abc")?.1
        validate(okResponse: responseClosure?(HttpRequest()), withBody: "not yet")
        validate(serverErrorResponse: responseClosure?(HttpRequest()))
        validate(okResponse: responseClosure?(HttpRequest()), withBody: "ok")
    }

    func testMockAPISStackKeepsReturningLastResponses() {
        let mockAPI = MockAPIStack(method: .get,
                                   pathTemplate: "/abc",
                                   stack: [
                                       .ok(.text("not yet")),
                                       .internalServerError,
                                       .ok(.text("ok")),
                                   ])
        mockAPI.register(onServer: server) { _, _ in .internalServerError }
        let responseClosure = server.get.router.route("GET", path: "/abc")?.1
        validate(okResponse: responseClosure?(HttpRequest()), withBody: "not yet")
        validate(serverErrorResponse: responseClosure?(HttpRequest()))
        validate(okResponse: responseClosure?(HttpRequest()), withBody: "ok")

        validate(okResponse: responseClosure?(HttpRequest()), withBody: "ok")
        validate(okResponse: responseClosure?(HttpRequest()), withBody: "ok")
        validate(okResponse: responseClosure?(HttpRequest()), withBody: "ok")
    }

    // MARK: - Internal

    func validate(serverErrorResponse response: HttpResponse?) {
        guard case .internalServerError = response else {
            fail("Unexpected response \(String(describing: response))")
            return
        }
    }

    func validate(okResponse response: HttpResponse?, withBody expecedText: String) {
        guard case .ok(let body) = response,
              case .text(let text) = body,
              text == expecedText else {
            fail("Unexpected response \(String(describing: response))")
            return
        }
    }

    private func validateRegister(_ method: HTTPMethod, routes: @escaping () -> [String]) {
        let mockAPI = MockAPI(method: method, pathTemplate: "/abc", response: .ok(.text("")))
        mockAPI.register(onServer: server) { _, _ in .internalServerError }
        expect(routes()[0]) == "/abc"
    }
}
