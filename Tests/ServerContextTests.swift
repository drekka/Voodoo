//
//  Created by Derek Clarkson on 21/9/2022.
//

import Foundation
@testable import Simulcra
import XCTest
import Nimble

class ServerContextTests: XCTestCase {

    func testRequestTemplateData() {
        var context = MockServerContext()
        context.cache["abc"] = "def"
        let templateData = context.requestTemplateData(adding: ["xyz":123])
        expect(templateData.count) == 3
        expect(templateData["mockServer"] as? String) == "http://127.0.0.1:8080"
        expect(templateData["abc"] as? String) == "def"
        expect(templateData["xyz"] as? Int) == 123
    }
}
