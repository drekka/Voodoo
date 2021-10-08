import XCTest
@testable import Simulcra
import Nimble

final class SimulcraTests: XCTestCase {
    
    func testStart() throws {
        let s1 = try MockServer(portRange: 8080...8081) {}
        try withExtendedLifetime(s1) {
            let s2 = try MockServer(portRange: 8080...8081) {}
        }
    }
}
