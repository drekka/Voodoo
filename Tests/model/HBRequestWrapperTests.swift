//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import SimulcraCore
import XCTest

class HBRequestWrapperTests: XCTestCase {

    func testBaseProperties() {
        let wrapper = HBRequest.mock(url: "https://\(HBRequest.mockServer)/xyz").asHTTPRequest
        expect(wrapper.method) == .GET
        expect(wrapper.path) == "/xyz"
    }

    func testHeaders() {
        let wrapper = HBRequest.mock(headers: ["def": "xyz"]).asHTTPRequest
        expect(wrapper.headers["def"]) == "xyz"
    }

    func testHeadersCaseInsensitivity() {
        let wrapper = HBRequest.mock(headers: ["def": "xyz"]).asHTTPRequest
        expect(wrapper.headers["DeF"]) == "xyz"
    }

    func testPathComponents() {
        expect(HBRequest.mock(url: "https://\(HBRequest.mockServer)").asHTTPRequest.pathComponents) == ["/"]
        expect(HBRequest.mock(url: "https://\(HBRequest.mockServer)/").asHTTPRequest.pathComponents) == ["/"]
        expect(HBRequest.mock(url: "https://\(HBRequest.mockServer)/abc/def").asHTTPRequest.pathComponents) == ["/", "abc", "def"]
        expect(HBRequest.mock(url: "https://\(HBRequest.mockServer)/abc//def/").asHTTPRequest.pathComponents) == ["/", "abc", "def"]
    }

    func testPathParameters() {
        let wrapper = HBRequest.mock(pathParameters: ["def": "xyz"]).asHTTPRequest
        expect(wrapper.pathParameters["def"]) == "xyz"
    }

    func testQueryParameters() {
        let wrapper = HBRequest.mock(url: "https://\(HBRequest.mockServer)/xyz?xxx=5&yyy=6").asHTTPRequest
        expect(wrapper.query) == "xxx=5&yyy=6"
        expect(wrapper.queryParameters["xxx"]) == "5"
        expect(wrapper.queryParameters["yyy"]) == "6"
    }

    func testQueryParametersPercentEncoding() {
        let wrapper = HBRequest.mock(url: "https://\(HBRequest.mockServer)/xyz?xxx=Hello%20world").asHTTPRequest
        expect(wrapper.query) == "xxx=Hello%20world"
        expect(wrapper.queryParameters["xxx"]) == "Hello world"
    }

    func testQueryParametersPlusEncoding() {
        let wrapper = HBRequest.mock(url: "https://\(HBRequest.mockServer)/xyz?xxx=Hello+world").asHTTPRequest
        expect(wrapper.query) == "xxx=Hello+world"
        expect(wrapper.queryParameters["xxx"]) == "Hello+world"
    }

    func testQueryParametersMultiples() {
        let wrapper = HBRequest.mock(url: "https://\(HBRequest.mockServer)/xyz?xxx=5&xxx=6&xxx=7").asHTTPRequest
        expect(wrapper.queryParameters["xxx"]) == ["5", "6", "7"]
    }

    func testJSONContent() {
        let wrapper = HBRequest.mock(contentType: "application/json",
                                     body: #"{"abc":"def"}"#).asHTTPRequest
        let json = wrapper.bodyJSON as! [String: Any]
        expect(json["abc"] as? String) == "def"
    }

    func testFormValues() {
        let wrapper = HBRequest.mock(contentType: "application/x-www-form-urlencoded",
                                     body: #"formField1=Hello%20world"#).asHTTPRequest
        expect(String(data: wrapper.body ?? Data(), encoding: .utf8)) == "formField1=Hello%20world"
        expect(wrapper.formParameters["formField1"]) == "Hello world"
    }
}