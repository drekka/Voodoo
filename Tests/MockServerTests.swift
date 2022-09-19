//
//  Created by Derek Clarkson on 11/10/21.
//

import Simulcra
import XCTest
import Nimble

class MockServerTests: XCTestCase {

    func testInit() throws {
        let server = MockServer()
        let address = try server.start()
        //expect(address).to(match(#"127\.0\.0\.1:\d\d\d\d"#))
    }
}
