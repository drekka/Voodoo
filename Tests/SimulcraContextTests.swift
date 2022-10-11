//
//  Created by Derek Clarkson on 21/9/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import SimulcraCore
import XCTest

class SimulcraContextTests: XCTestCase {

    var context: MockSimulcraContext!

    override func setUp() {
        context = MockSimulcraContext()
    }

    func testRequestTemplateDataWithNil() {

        context.cache["abc"] = "def"
        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: nil)

        expect(templateData.count) == 2
        expect(templateData["abc"] as? String) == "def"
        expect(templateData["mockServer"] as? String) == HBRequest.mockServer
    }

    func testRequestTemplateData() {

        context.cache["abc"] = "def"
        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: ["xyz": 123])

        expect(templateData.count) == 3
        expect(templateData["abc"] as? String) == "def"
        expect(templateData["xyz"] as? Int) == 123
        expect(templateData["mockServer"] as? String) == HBRequest.mockServer
    }

    func testRequestTemplateDataOverridesMockServer() {

        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: ["mockServer": "http://\(HBRequest.mockHost):9999"])

        expect(templateData.count) == 1
        expect(templateData["mockServer"] as? String) == "http://\(HBRequest.mockHost):9999"
    }

    func testRequestTemplateDataUpdatesWhenSameKey() {

        context.cache["abc"] = "def"
        let request = HBRequest.mock().asHTTPRequest
        let templateData = context.requestTemplateData(forRequest: request, adding: ["abc": 123])

        expect(templateData.count) == 2
        expect(templateData["abc"] as? Int) == 123
        expect(templateData["mockServer"] as? String) == HBRequest.mockServer
    }
}
