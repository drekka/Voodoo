//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import Nimble
@testable import Simulcra
import XCTest

class HBRequestWrapperTests: XCTestCase {

    func testBaseProperties() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1:8080/xyz"))
        expect(wrapper.method) == .GET
        expect(wrapper.path) == "/xyz"
    }

    func testHeaders() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1", headers: ["def": "xyz"]))
        expect(wrapper.headers["def"]) == "xyz"
    }

    func testPathParameters() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1", pathParameters: ["def": "xyz"]))
        expect(wrapper.pathParameters["def"]) == "xyz"
    }

    func testQueryParameters() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1/xyz?xxx=5&yyy=6"))
        expect(wrapper.query) == "xxx=5&yyy=6"
        expect(wrapper.queryParameters["xxx"]) == "5"
        expect(wrapper.queryParameters["yyy"]) == "6"
    }

    func testQueryParametersPercentEncoding() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1/xyz?xxx=Hello%20world"))
        expect(wrapper.query) == "xxx=Hello%20world"
        expect(wrapper.queryParameters["xxx"]) == "Hello world"
    }

    func testQueryParametersPlusEncoding() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1/xyz?xxx=Hello+world"))
        expect(wrapper.query) == "xxx=Hello+world"
        expect(wrapper.queryParameters["xxx"]) == "Hello+world"
    }

    func testQueryParametersMultiples() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1/xyz?xxx=5&xxx=6&xxx=7"))
        expect(wrapper.queryParameters["xxx"]) == ["5", "6", "7"]
    }

    func testJSONContent() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1",
                                                                   contentType: "application/json",
                                                                   body: #"{"abc":"def"}"#))
        let json = wrapper.bodyJSON as! [String: Any]
        expect(json["abc"] as? String) == "def"
    }

    func testFormValues() {
        let wrapper = HBRequestWrapper(request: MockRequest.create(url: "https://127.0.0.1",
                                                                   contentType: "application/x-www-form-urlencoded",
                                                                   body: #"formField1=Hello%20world"#))
        expect(String(data: wrapper.body ?? Data(), encoding: .utf8)) == "formField1=Hello%20world"
        expect(wrapper.formParameters["formField1"]) == "Hello world"
    }
}
