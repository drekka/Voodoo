//
//  Created by Derek Clarkson on 17/9/2022.
//

import Foundation
import Hummingbird
import Nimble
import NIOHTTP1
@testable import Voodoo
import XCTest

class AdminConsoleIntegrationTests: XCTestCase, IntegrationTesting {

    var server: VoodooServer!

    override func setUp() async throws {
        try await super.setUp()
        server = try VoodooServer(verbose: true)
    }

    override func tearDown() {
        tearDownServer()
        super.tearDown()
    }

    func testSettingDelay() async throws {

        server.add(.GET, "/abc", response: .ok())

        // Check a basic request executes < 0.5 sec.
        let clock = ContinuousClock()
        let elapsed =  await clock.measure {
            await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        }
        expect(elapsed.seconds) < 0.5

        // now set a delay.
        expect(self.server.delay) == 0.0
        await executeAPICall(.PUT, VoodooServer.adminDelay + "/0.5", andExpectStatusCode: 200)
        expect(self.server.delay) == 0.5

        // Check a basic request executes > 0.5 sec.
        let clock2 = ContinuousClock()
        let elapsed2 =  await clock2.measure {
            await executeAPICall(.GET, "/abc", andExpectStatusCode: 200)
        }
        expect(elapsed2.seconds) > 0.5
    }

    func testShutdown() async {
        await executeAPICall(.POST, VoodooServer.adminShutdown, andExpectStatusCode: 200)
        let response = await executeAPICall(.GET, "/abc")
        if let error = response.error as? URLError {
            expect(error.errorCode) == -1004
            expect(error.localizedDescription) == "Could not connect to the server."
        } else {
            fail("Unexpected error \(response.error?.localizedDescription ?? "")")
        }

    }
}



extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1000_000_000_000_000_000.0
    }
}
