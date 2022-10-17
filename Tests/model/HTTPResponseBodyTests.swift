//
//  File.swift
//
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache
import Nimble
@testable import SimulcraCore
import XCTest

class HTTPResponseBodyTests: XCTestCase {

    private var context: SimulcraContext!

    override func setUp() {
        super.setUp()
        context = MockSimulcraContext()
    }

    func testEmpty() throws {
        let context = MockSimulcraContext()
        let request = HBRequest.mock().asHTTPRequest
        let hbBody = try HTTPResponse.Body.empty.hbBody(forRequest: request, serverContext: context)
        expect(hbBody.0) == .empty
        expect(hbBody.1) == nil
    }

    func testText() throws {
        try assert(.text(#"def {{xyz}}"#, templateData: ["xyz": 123]),
                   generates: #"def 123"#,
                   contentType: ContentType.textPlain)
    }

    func testData() throws {
        try assert(.data("abc".data(using: .utf8)!, contentType: ContentType.textPlain),
                   generates: "abc",
                   contentType: ContentType.textPlain)
    }

    func testTemplate() throws {
        let template = try HBMustacheTemplate(string: "Hello {{xyz}}")
        context.mustacheRenderer.register(template, named: "fred")
        try assert(.template("fred", templateData: ["xyz": 123], contentType: ContentType.textPlain),
                   generates: #"Hello 123"#,
                   contentType: ContentType.textPlain)
    }

    func testFile() throws {
        let url = Bundle.testBundle.url(forResource: "Test files/Simple", withExtension: "html")!
        try assert(.file(url, contentType: ContentType.textHTML),
                   generates: #"<html><body></body></html>\#n"#,
                   contentType: ContentType.textHTML)
    }

    // MARK: - JSON types

    func testStructuredWithDictionary() throws {
        try assert(.structured([
                       "abc": "def {{xyz}}",
                   ],
                   templateData: ["xyz": 123]),
                   generates: #"{"abc":"def 123"}"#,
                   contentType: ContentType.applicationJSON)
    }

    func testStructuredWithEncodable() throws {

        struct StructuredTest: Codable {
            let abc: String
        }

        let encodable = StructuredTest(abc: #"def {{xyz}}"#)
        try assert(.structured(encodable.structuredData, templateData: ["xyz": 123]),
                   generates: #"{"abc":"def 123"}"#,
                   contentType: ContentType.applicationJSON)
    }

    func testStructuredWithDictionaryToYAML() throws {
        try assert(.structured([
                       "abc": "def {{xyz}}",
                   ],
                   output: .yaml,
                   templateData: ["xyz": 123]),
                   generates: "abc: def 123\n",
                   contentType: ContentType.applicationYAML)
    }

    // MARK: - Support functions

    func assert(file: StaticString = #file, line: UInt = #line,
                _ body: HTTPResponse.Body,
                generates expectedBody: String,
                contentType expectedContentType: String?) throws {
        let request = HBRequest.mock().asHTTPRequest
        let hbBody = try body.hbBody(forRequest: request, serverContext: context)
        expect(file: file, line: line, hbBody.0) == expectedBody.hbResponseBody
        expect(file: file, line: line, hbBody.1) == expectedContentType
    }
}

class HTTPREsponseBodyDecodableTests: XCTestCase {

    func testDecodeEmpty() throws {
        try assert(#"{"type":"empty"}"#, decodesTo: .empty)
    }

    func testDecodeText() throws {
        try assert(#"{"type":"text","text":"abc"}"#, decodesTo: .text("abc"))
    }

    func testDecodeData() throws {
        let data = "abc".data(using: .utf8)!
        try assert(#"{"type":"data","data":"\#(data.base64EncodedString())","contentType":"ct"}"#,
                   decodesTo: .data(data, contentType: "ct"))
    }

    func testDecodeJSON() throws {
        try assert(#"""
        {
            "type":"json",
            "data":"{\"abc\":\"xyz\"}"
        }
        """#, decodesTo: .structured(#"{"abc":"xyz"}"#))
    }

    func testUnknownError() throws {
        let data = #"{"type":"xxxx"}"#.data(using: .utf8)!
        do {
            _ = try JSONDecoder().decode(HTTPResponse.Body.self, from: data)
            fail("Error not thrown")
        } catch DecodingError.dataCorrupted(let context) {
            expect(context.codingPath.count) == 1
            expect(context.codingPath[0].stringValue) == "type"
            expect(context.debugDescription) == "Unknown value 'xxxx'"
        }
    }

    // MARK: - Support functions

    func assert(_ json: String, decodesTo expectedBody: HTTPResponse.Body) throws {
        let data = json.data(using: .utf8)!
        let body = try JSONDecoder().decode(HTTPResponse.Body.self, from: data)
        expect(body) == expectedBody
    }
}
