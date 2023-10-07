//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Hummingbird
import HummingbirdMustache
import Nimble
@testable import Voodoo
import XCTest
import Yams

class HTTPResponseBodyTests: XCTestCase {

    private var context: VoodooContext!

    override func setUp() {
        super.setUp()
        context = MockVoodooContext()
    }

    // MARK: - Response body generation

    func testEmpty() throws {
        let context = MockVoodooContext()
        let request = HBRequest.mock().asHTTPRequest
        let hbBody = try HTTPResponse.Body.empty.hbBody(forRequest: request, serverContext: context)
        expect(hbBody.0) == .empty
        expect(hbBody.1) == nil
    }

    func testText() throws {
        try assert(.text(#"def {{xyz}}"#, templateData: ["xyz": 123]),
                   generates: #"def 123"#,
                   contentType: Header.ContentType.textPlain)
    }

    func testData() throws {
        try assert(.data("abc".data(using: .utf8)!, contentType: Header.ContentType.textPlain),
                   generates: "abc",
                   contentType: Header.ContentType.textPlain)
    }

    func testemplate() throws {
        let template = try HBMustacheTemplate(string: "Hello {{xyz}}")
        context.mustacheRenderer.register(template, named: "fred")
        try assert(.template("fred", templateData: ["xyz": 123], contentType: Header.ContentType.textPlain),
                   generates: #"Hello 123"#,
                   contentType: Header.ContentType.textPlain)
    }

    func testFile() throws {
        let url = Bundle.testBundle.url(forResource: "files/Simple", withExtension: "html")!
        try assert(.file(url, contentType: Header.ContentType.textHTML),
                   generates: #"<html><body></body></html>\#n"#,
                   contentType: Header.ContentType.textHTML)
    }

    // MARK: - JSON types

    func testJSONWithDictionary() throws {
        try assert(.json([
                       "abc": "def {{xyz}}",
                   ],
                   templateData: ["xyz": 123]),
                   generates: #"{"abc":"def 123"}"#,
                   contentType: Header.ContentType.applicationJSON)
    }

    func testJSONWithEncodable() throws {

        struct JSONTest: Codable {
            let abc: String
        }

        let encodable = JSONTest(abc: #"def {{xyz}}"#)
        try assert(.json(encodable, templateData: ["xyz": 123]),
                   generates: #"{"abc":"def 123"}"#,
                   contentType: Header.ContentType.applicationJSON)
    }

    // MARK: - YAML types

    func testYAMLWithDictionary() throws {
        try assert(.yaml([
                       "abc": "def {{xyz}}",
                   ],
                   templateData: ["xyz": 123]),
                   generates: "abc: def 123\n",
                   contentType: Header.ContentType.applicationYAML)
    }

    func testYAMLWithEncodable() throws {

        struct YAMLTest: Codable {
            let abc: String
        }

        let encodable = YAMLTest(abc: #"def {{xyz}}"#)
        try assert(.yaml(encodable, templateData: ["xyz": 123]),
                   generates: "abc: def 123\n",
                   contentType: Header.ContentType.applicationYAML)
    }

    // MARK: - Support functions

    func assert(file: FileString = #file, line: UInt = #line,
                _ body: HTTPResponse.Body,
                generates expectedBody: String,
                contentType expectedContentType: String?) throws {
        let request = HBRequest.mock().asHTTPRequest
        let hbBody = try body.hbBody(forRequest: request, serverContext: context)
        expect(file: file, line: line, hbBody.0) == expectedBody.hbResponseBody
        expect(file: file, line: line, hbBody.1) == expectedContentType
    }
}

class HTTPResponseBodyDecodableTests: XCTestCase {

    func testDecodeText() throws {
        try assert(#"""
                   text: abc
                   """#,
                   decodesTo: .text("abc"))
    }

    func testDecodeJSON() throws {
        try assert(#"""
                   json:
                     abc: xyz
                   """#,
                   decodesTo: .json(["abc": "xyz"]))
    }

    func testDecodeYAML() throws {
        try assert(#"""
                   yaml:
                     abc: xyz
                   """#,
                   decodesTo: .yaml(["abc": "xyz"]))
    }

    func testDecodeFile() throws {
        try assert(#"""
                   file: abc/def.md
                   contentType: application/markdown
                   """#,
                   decodesTo: .file(fileURL(forPath: "abc/def.md"), contentType: "application/markdown"))
    }

    func testDecodeFileWithoutContentType() throws {
        try assert(#"""
                   file: abc/def.json
                   """#,
                   decodesTo: .file(fileURL(forPath: "abc/def.json"), contentType: "application/json"))
    }

    func testDecodeTemplate() throws {
        try assert(#"""
                   template: books
                   contentType: application/json
                   """#,
                   decodesTo: .template("books", contentType: "application/json"))
    }

    func testDecodeTemplateWithoutContentType() throws {
        try assert(#"""
                   template: books
                   """#,
                   decodesTo: .template("books", contentType: "application/json"))
    }

    func testUnknownError() throws {
        let data = #"""
        abc: 123
        templateData: ~
        """#
        .data(using: .utf8)!
        do {
            _ = try YAMLDecoder().decode(HTTPResponse.Body.self, from: data)
            fail("Error not thrown")
        } catch let DecodingError.dataCorrupted(context) {
            expect(context.codingPath.count) == 0
            expect(context.debugDescription) == "Unable to determine response body. Possibly incorrect or invalid keys."
        }
    }

    // MARK: - Support functions

    func assert(_ yml: String,
                decodesTo expectedBody: HTTPResponse.Body,
                file: FileString = #file, line: UInt = #line) throws {
        let body = try YAMLDecoder().decode(HTTPResponse.Body.self, from: yml.data(using: .utf8)!)
        expect(file: file, line: line, body) == expectedBody
    }

    func fileURL(forPath path: String) -> URL {
        if #available(macOS 13, iOS 16, *) {
            return URL(filePath: path)
        } else {
            return URL(fileURLWithPath: path)
        }
    }
}
