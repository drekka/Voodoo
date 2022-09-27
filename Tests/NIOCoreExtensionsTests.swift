//
//  Created by Derek Clarkson on 21/9/2022.
//

import Foundation
import Nimble
import NIOCore
@testable import SimulcraCore
import XCTest

class NIOCoreExtensionsTests: XCTestCase {

    func testGettingBytes() {
        let buffer = ByteBuffer(string: "abc")
        expect(buffer.data) == "abc".data(using: .utf8)
    }
}
