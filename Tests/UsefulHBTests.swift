//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation
import Hummingbird
import Nimble
import XCTest

// Tests that help us understand how HB works.

extension String {
    var urlPathComponents: [String.SubSequence] {
        ["/"] + self.split(separator: "/")
    }
}

class UsefulHBTests: XCTestCase {

    func testPathInterpretation() {
        let r1: HBRequest = MockRequest.create(url: "http://127.0.0.1:8080")
        expect(r1.uri.path) == "/"

        let r2: HBRequest = MockRequest.create(url: "http://127.0.0.1:8080/")
        expect(r2.uri.path) == "/"

        let r3: HBRequest = MockRequest.create(url: "http://127.0.0.1:8080/abc/def")
        expect(r3.uri.path) == "/abc/def"

        let r4: HBRequest = MockRequest.create(url: "http://127.0.0.1:8080/abc//def")
        expect(r4.uri.path) == "/abc//def"

        // Now how we'll do it.
        let r5: HBRequest = MockRequest.create(url: "http://127.0.0.1:8080/abc//def")
        expect(r5.uri.path.urlPathComponents) == ["/", "abc", "def"]
    }
}
