//
//  File.swift
//
//
//  Created by Derek Clarkson on 5/10/2022.
//

import Foundation
import Nimble
@testable import SimulcraCore
import XCTest

class HTTPResponseExtensionsTests: XCTestCase {

    func testDecodeOk() throws {
        try assert(#"{"statusCode":200}"#, decodesTo: .ok())
    }

    // MARK: - Helpers

    func assert(_ json: String, decodesTo expectedResponse: HTTPResponse) throws {
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(HTTPResponse.self, from: data)
        expect(response) == expectedResponse
    }
}

class HTTPREsponseBodyExtensionsTests: XCTestCase {

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
            "json":"{\"abc\":\"xyz\"}"
        }
        """#, decodesTo: .json(#"{"abc":"xyz"}"#))
    }

    func assert(_ json: String, decodesTo expectedBody: HTTPResponse.Body) throws {
        let data = json.data(using: .utf8)!
        let body = try JSONDecoder().decode(HTTPResponse.Body.self, from: data)
        expect(body) == expectedBody
    }
}
