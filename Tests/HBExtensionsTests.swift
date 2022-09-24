//
//  Created by Derek Clarkson on 21/9/2022.
//

import Foundation
import Hummingbird
import Nimble
@testable import Simulcra
import XCTest

class HBExtensionsTests: XCTestCase {

    func testURL() {
        let configuration = HBApplication.Configuration(address: .hostname("127.0.0.1", port: 12345))
        let server = HBApplication(configuration: configuration)
        expect(server.address.absoluteString) == "http://127.0.0.1:12345"
    }
}
