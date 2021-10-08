//
//  Created by Derek Clarkson on 3/10/21.
//

import Nimble
@testable import Simulcra
import Swifter
import XCTest

class HTTPResponseBodyTests: XCTestCase {

    struct TestClass: Codable {
        let abc: String
    }

    func testJSONObject() throws {
        let obj = TestClass(abc: "xyz")
        let response = try HTTPResponseBody.json(obj).asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .json(let anyObj) = response,
               let resultObj = anyObj as? TestClass,
               resultObj.abc == obj.abc {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testJSONFile() throws {
        let fileUrl = Bundle.testBundle.url(forResource: "Simple", withExtension: "json")!
        let response = try HTTPResponseBody.jsonFile(fileUrl).asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .json(let anyObj) = response,
               let resultObj = anyObj as? [String: Any],
               resultObj["abc"] as? String == "xyz" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testJSONFileNotFound() throws {
        do {
            _ = try HTTPResponseBody.jsonFile(URL(string: "file://NotAFile.json")!).asSwifterResponseBody(forRequest: HttpRequest())
            fail("Expected exception not thrown")
        } catch {
            expect {
                if case SimulcraError.unableToReadFile(let file) = error,
                   file.hasSuffix("NotAFile.json") {
                    return { .succeeded }
                }
                return { .failed(reason: "wrong enum case") }
            }.to(succeed())
        }
    }

    func testJSONFileWhenNotValidJSON() throws {
        let fileUrl = Bundle.testBundle.url(forResource: "Invalid", withExtension: "json")!
        do {
            _ = try HTTPResponseBody.jsonFile(fileUrl).asSwifterResponseBody(forRequest: HttpRequest())
            fail("Exception not thrown.")
        } catch {
            switch error {
            case SimulcraError.invalidFileContents(let file):
                expect(file.hasSuffix("Invalid.json")) == true
            default:
                fail("Unexpected error \(error)")
            }
        }
    }

    func testHTML() throws {
        let response = try HTTPResponseBody.html("<html></html>").asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .html(let html) = response, html == "<html></html>" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testHTMLFile() throws {
        let fileUrl = Bundle.testBundle.url(forResource: "Simple", withExtension: "html")!
        let response = try HTTPResponseBody.htmlFile(fileUrl).asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .html(let html) = response, html == "<html><body></body></html>\n" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testHTMLFileNotFound() throws {
        do {
            _ = try HTTPResponseBody.htmlFile(URL(string: "file://NotAFile.html")!).asSwifterResponseBody(forRequest: HttpRequest())
            fail("Expected exception not thrown")
        } catch {
            expect {
                if case SimulcraError.unableToReadFile(let file) = error,
                   file.hasSuffix("NotAFile.html") {
                    return { .succeeded }
                }
                return { .failed(reason: "wrong enum case") }
            }.to(succeed())
        }
    }

    func testHTMLBody() throws {
        let response = try HTTPResponseBody.htmlBody("<h1>Hello</h1>").asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .htmlBody(let body) = response, body == "<h1>Hello</h1>" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testText() throws {
        let response = try HTTPResponseBody.text("some text").asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .text(let text) = response, text == "some text" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testData() throws {
        let sourceData = "hello".data(using: .utf8)!
        let response = try HTTPResponseBody.data(sourceData, contentType: "abc").asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .data(let data, let contentType) = response,
               String(data: data, encoding: .utf8)! == "hello",
               contentType == "abc" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }

    func testCustomCustomText() throws {
        let response = try HTTPResponseBody.custom { _ in
            .custom { _ in
                .text("some text")
            }
        }.asSwifterResponseBody(forRequest: HttpRequest())
        expect {
            if case .text(let text) = response, text == "some text" {
                return { .succeeded }
            }
            return { .failed(reason: "wrong enum case") }
        }.to(succeed())
    }
}
