//
//  Created by Derek Clarkson on 21/9/2022.
//

import AnyCodable
import Foundation
import Hummingbird
import Nimble
@testable import Voodoo
import XCTest

class VoodooContextTests: XCTestCase {

    var context: MockVoodooContext!

    private let host = "127.0.0.1:8080"

    override func setUp() {
        context = MockVoodooContext()
    }

    func testRequestTemplateDataWithNil() {

        context.cache["abc"] = "def"
        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: nil)

        expect(templateData.count) == 2
        expect(templateData["abc"] as? String) == "def"
        expect(templateData["mockServer"] as? String) == host
    }

    func testRequestTemplateData() {

        context.cache["abc"] = "def"
        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: ["xyz": 123])

        expect(templateData.count) == 3
        expect(templateData["abc"] as? String) == "def"
        expect(templateData["xyz"] as? Int) == 123
        expect(templateData["mockServer"] as? String) == host
    }

    func testRequestTemplateDataOverridesMockServer() {

        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: ["mockServer": "http://127.0.0.1:9999"])

        expect(templateData.count) == 1
        expect(templateData["mockServer"] as? String) == "http://127.0.0.1:9999"
    }

    func testRequestTemplateDataUpdatesWhenSameKey() {

        context.cache["abc"] = "def"
        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: ["abc": 123])

        expect(templateData.count) == 2
        expect(templateData["abc"] as? Int) == 123
        expect(templateData["mockServer"] as? String) == host
    }
}
