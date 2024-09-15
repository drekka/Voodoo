//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Hummingbird
import Nimble
import PathKit
import XCTest
import Yams

@testable import Voodoo

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
                   contentType: HTTPHeader.ContentType.textPlain)
    }

    func testData() throws {
        try assert(.data("abc".data(using: .utf8)!, contentType: HTTPHeader.ContentType.textPlain),
                   generates: "abc",
                   contentType: HTTPHeader.ContentType.textPlain)
    }

    func testemplate() throws {
        context.templateRenderer.register(template: "Hello {{xyz}}", withName: "fred")
        try assert(.template("fred", templateData: ["xyz": 123], contentType: HTTPHeader.ContentType.textPlain),
                   generates: #"Hello 123"#,
                   contentType: HTTPHeader.ContentType.textPlain)
    }

    func testFile() throws {
        let url = Bundle.testBundle.url(forResource: "files/Simple", withExtension: "html")!
        try assert(.file(Path(url.path()), contentType: HTTPHeader.ContentType.textHTML),
                   generates: #"<html><body></body></html>\#n"#,
                   contentType: HTTPHeader.ContentType.textHTML)
    }

    // MARK: - JSON types

    func testJSONWithDictionary() throws {
        try assert(.json([
                       "abc": "def {{xyz}}",
                   ],
                   templateData: ["xyz": 123]),
                   generates: #"{"abc":"def 123"}"#,
                   contentType: HTTPHeader.ContentType.applicationJSON)
    }

    func testJSONWithEncodable() throws {

        struct JSONTest: Codable {
            let abc: String
        }

        let encodable = JSONTest(abc: #"def {{xyz}}"#)
        try assert(.json(encodable, templateData: ["xyz": 123]),
                   generates: #"{"abc":"def 123"}"#,
                   contentType: HTTPHeader.ContentType.applicationJSON)
    }

    // MARK: - YAML types

    func testYAMLWithDictionary() throws {
        try assert(.yaml([
                       "abc": "def {{xyz}}",
                   ],
                   templateData: ["xyz": 123]),
                   generates: "abc: def 123\n",
                   contentType: HTTPHeader.ContentType.applicationYAML)
    }

    func testYAMLWithEncodable() throws {

        struct YAMLTest: Codable {
            let abc: String
        }

        let encodable = YAMLTest(abc: #"def {{xyz}}"#)
        try assert(.yaml(encodable, templateData: ["xyz": 123]),
                   generates: "abc: def 123\n",
                   contentType: HTTPHeader.ContentType.applicationYAML)
    }

    // MARK: - Support functions

    func assert(file: FileString = #file, line: UInt = #line,
                _ body: HTTPResponse.Body,
                generates expectedBody: String,
                contentType expectedContentType: HTTPHeader.ContentType?) throws {
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
                   decodesTo: .file("abc/def.md", contentType: .applicationMarkdown))
    }

    func testDecodeFileWithoutContentType() throws {
        try assert(#"""
                   file: abc/def.json
                   """#,
                   decodesTo: .file("abc/def.json", contentType: .applicationJSON))
    }

    func testDecodeTemplate() throws {
        try assert(#"""
                   template: books
                   contentType: application/json
                   """#,
                   decodesTo: .template("books", contentType: .applicationJSON))
    }

    func testDecodeTemplateWithoutContentType() throws {
        try assert(#"""
                   template: books
                   """#,
                   decodesTo: .template("books", contentType: .applicationJSON))
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
        } catch DecodingError.dataCorrupted(let context) {
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
}
