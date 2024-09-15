import Nimble
@testable import Voodoo
import XCTest

class HeaderTests: XCTestCase {

    func testContentTypeOther() {
        let other = HTTPHeader.ContentType.other("Abc")
        expect(other.contentType) == "abc"
    }

    func testContentTypeComparison() {
        expect(HTTPHeader.ContentType.applicationJSON) == .applicationJSON
        expect(HTTPHeader.ContentType.applicationJSON) != .textHTML
    }

    func testContentTypeAndStringComparison() {
        expect(HTTPHeader.ContentType.applicationJSON.contentType) == "application/json"
        expect(HTTPHeader.ContentType.applicationJSON.contentType) != "text/html"
        expect(HTTPHeader.ContentType.applicationJSON.contentType) != nil
    }

    func testStringAndContentTypeComparison() {
        expect("application/json") == HTTPHeader.ContentType.applicationJSON.contentType
        expect("text/html") != HTTPHeader.ContentType.applicationJSON.contentType
    }
}
