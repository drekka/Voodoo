//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import Voodoo
import XCTest

class HBRequestWrapperTests: XCTestCase {

    func testBaseProperties() {
        let wrapper = HBRequest.mock(path: "/xyz").asHTTPRequest
        expect(wrapper.method) == .GET
        expect(wrapper.path) == "/xyz"
    }

    func testHeaders() {
        let wrapper = HBRequest.mock(headers: ["def": "xyz"]).asHTTPRequest
        expect(wrapper.headers.def) == "xyz"
    }

    func testHeadersCaseInsensitivity() {
        let wrapper = HBRequest.mock(headers: ["def": "xyz"]).asHTTPRequest
        expect(wrapper.headers["DeF"]) == "xyz"
    }

    func testPathComponents() {
        expect(HBRequest.mock(path: "").asHTTPRequest.pathComponents) == ["/"]
        expect(HBRequest.mock(path: "/").asHTTPRequest.pathComponents) == ["/"]
        expect(HBRequest.mock(path: "/abc/def").asHTTPRequest.pathComponents) == ["/", "abc", "def"]
        expect(HBRequest.mock(path: "/abc//def/").asHTTPRequest.pathComponents) == ["/", "abc", "def"]
    }

    func testPathParameters() {
        let wrapper = HBRequest.mock(pathParameters: ["def": "xyz"]).asHTTPRequest
        expect(wrapper.pathParameters["def"]) == "xyz"
    }

    func testQueryParameters() {
        let wrapper = HBRequest.mock(path: "/xyz", query: "xxx=5&yyy=6").asHTTPRequest
        expect(wrapper.query) == "xxx=5&yyy=6"
        expect(wrapper.queryParameters["xxx"]) == "5"
        expect(wrapper.queryParameters["yyy"]) == "6"
    }

    func testQueryParametersPercentEncoding() {
        let wrapper = HBRequest.mock(path: "/xyz", query: "xxx=Hello world").asHTTPRequest
        expect(wrapper.query) == "xxx=Hello%20world"
        expect(wrapper.queryParameters["xxx"]) == "Hello world"
    }

    func testQueryParametersPlusEncoding() {
        let wrapper = HBRequest.mock(path: "/xyz", query: "xxx=Hello+world").asHTTPRequest
        expect(wrapper.query) == "xxx=Hello+world"
        expect(wrapper.queryParameters["xxx"]) == "Hello+world"
    }

    func testQueryParametersMultiples() {
        let wrapper = HBRequest.mock(path: "/xyz", query: "xxx=5&xxx=6&xxx=7").asHTTPRequest
        expect(wrapper.queryParameters["xxx"]) == ["5", "6", "7"]
    }

    func testJSONContent() {
        let wrapper = HBRequest.mock(contentType: HTTPHeader.ContentType.applicationJSON,
                                     body: #"{"abc":"def"}"#).asHTTPRequest
        let json = wrapper.bodyJSON as! [String: Any]
        expect(json["abc"] as? String) == "def"
    }

    func testYAMLContent() {
        let wrapper = HBRequest.mock(contentType: HTTPHeader.ContentType.applicationYAML,
                                     body: #"""
                                     abc: def
                                     """#).asHTTPRequest
        let json = wrapper.bodyYAML as! [String: Any]
        expect(json["abc"] as? String) == "def"
    }

    func testFormValues() {
        let wrapper = HBRequest.mock(contentType: HTTPHeader.ContentType.applicationFormData,
                                     body: #"formField1=Hello%20world&formField2&formField3=Goodbye!"#).asHTTPRequest

        expect(String(data: wrapper.body ?? Data(), encoding: .utf8)) == "formField1=Hello%20world&formField2&formField3=Goodbye!"

        expect(wrapper.formParameters.count) == 2

        expect(wrapper.formParameters["formField1"]) == "Hello world"
        expect(wrapper.formParameters["formField2"]).to(beNil())
        expect(wrapper.formParameters["formField3"]) == "Goodbye!"

        expect(wrapper.formParameters.formField1) == "Hello world"
        expect(wrapper.formParameters.formField2).to(beNil())
        expect(wrapper.formParameters.formField3) == "Goodbye!"
    }

    func testFormValuesFromExtendedContentType() {
        let wrapper = HBRequest.mock(contentType: HTTPHeader.ContentType.applicationFormData,
                                     body: #"formField1=Hello%20world&formField2&formField3=Goodbye!"#).asHTTPRequest

        expect(String(data: wrapper.body ?? Data(), encoding: .utf8)) == "formField1=Hello%20world&formField2&formField3=Goodbye!"

        expect(wrapper.formParameters.count) == 2

        expect(wrapper.formParameters["formField1"]) == "Hello world"
        expect(wrapper.formParameters["formField2"]).to(beNil())
        expect(wrapper.formParameters["formField3"]) == "Goodbye!"

        expect(wrapper.formParameters.formField1) == "Hello world"
        expect(wrapper.formParameters.formField2).to(beNil())
        expect(wrapper.formParameters.formField3) == "Goodbye!"
    }

    func testDecodingJSONBody() {

        struct Payload: Decodable {
            let x: Int
            let y: String
        }

        let wrapper = HBRequest.mock(contentType: HTTPHeader.ContentType.applicationJSON,
                                     body: #"{"x":123, "y":"Hello"}"#).asHTTPRequest
        let payload = wrapper.decodeBodyJSON(as: Payload.self)!
        expect(payload.x) == 123
        expect(payload.y) == "Hello"
    }
}
