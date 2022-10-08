//
//  File.swift
//
//
//  Created by Derek Clarkson on 7/10/2022.
//

import Foundation
import Nimble
@testable import SimulcraCore
import XCTest

class EndpointTests: XCTestCase {

    func testDecode() throws {
        let data = #"""
        {
            "signature": "post /abc",
            "response": {
                "statusCode" : 200
            }
        }
        """#.data(using: .utf8)!
        let endpoint = try JSONDecoder().decode(Endpoint.self, from: data)

        expect(endpoint.method) == .POST
        expect(endpoint.path) == "/abc"
        expect(endpoint.response) == .ok()
    }

    func testDecodeWithResponse() throws {
        let data = #"""
        {
            "signature": "post /abc",
            "response": {
                "statusCode" : 200,
                "headers": {
                    "abc": "123"
                },
                "body": {
                    "type": "text",
                    "text": "Hey everyone - {{def}}",
                    "templateData": {
                        "def": "hello world!"
                    }
                }
            }
        }
        """#.data(using: .utf8)!
        let endpoint = try JSONDecoder().decode(Endpoint.self, from: data)

        expect(endpoint.method) == .POST
        expect(endpoint.path) == "/abc"
        expect(endpoint.response) == .ok(headers: ["abc": "123"],
                                         body: .text("Hey everyone - {{def}}",
                                                     templateData: ["def": "Hello world!"]))
    }
}
