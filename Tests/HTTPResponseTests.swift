//
//  Created by Derek Clarkson on 1/10/21.
//

import Nimble
@testable import Simulcra
import Swifter
import XCTest

class HTTPResponseTests: XCTestCase {

    func testSwitchProtocols() throws {
        let headers: [String: String] = ["abc": "5"]
        let handler: (Socket) -> Void = { _ in }
        let response = try HTTPResponse.switchProtocols(headers, handler).asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .switchProtocols(let resultHeaders, _) = response,
               resultHeaders["abc"] == "5" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testOk() throws {
        let response = try HTTPResponse.ok(.text("")).asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .ok = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testCreated() throws {
        let response = try HTTPResponse.created.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .created = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testAccepted() throws {
        let response = try HTTPResponse.accepted.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .accepted = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testMovedPermanently() throws {
        let response = try HTTPResponse.movedPermanently("http://abc.com").asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .movedPermanently(let url) = response,
               url == "http://abc.com" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testTemporarily() throws {
        let response = try HTTPResponse.movedTemporarily("http://abc.com").asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .movedTemporarily(let url) = response,
               url == "http://abc.com" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testBadRequest() throws {
        let response = try HTTPResponse.badRequest(.text("hello")).asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .badRequest(let responseBody) = response,
               case .text(let text) = responseBody,
               text == "hello" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testBadRequestWithNilBody() throws {
        let response = try HTTPResponse.badRequest(nil).asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .badRequest(let responseBody) = response,
               responseBody == nil {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }
    
    func testUnauthorized() throws {
        let response = try HTTPResponse.unauthorized.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .unauthorized = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testForbidden() throws {
        let response = try HTTPResponse.forbidden.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .forbidden = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testNotFound() throws {
        let response = try HTTPResponse.notFound.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .notFound = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }
    
    func testNotAcceptable() throws {
        let response = try HTTPResponse.notAcceptable.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .notAcceptable = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testTooManyRequests() throws {
        let response = try HTTPResponse.tooManyRequests.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .tooManyRequests = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }
    
    func testInternalServerError() throws {
        let response = try HTTPResponse.internalServerError.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if case .internalServerError = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testRaw() throws {
        let headers:[String:String] = ["abc": "5"]
        let response = try HTTPResponse.raw(501, "501 error", headers) { writer in
            
        }.asSwifterResponse(forRequest: HttpRequest())
        expect {
            if response.statusCode == 501, response.headers()["abc"] == "5" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testCustomCustomCustomTooManyRequests() throws {

        let response = try HTTPResponse.custom { _ in
            .custom { _ in
                .custom { _ in
                    .custom { _ in
                        .tooManyRequests
                    }
                }
            }
        }.asSwifterResponse(forRequest: HttpRequest())

        expect {
            if case .tooManyRequests = response {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }
}
