//
//  Created by Derek Clarkson on 11/10/2022.
//

import Nimble
import Voodoo
import XCTest

enum TestError: Error {
    case x
}

class VoodooErrorTests: XCTestCase {

    func testMessages() {
        expect(VoodooError.directoryNotExists("/abc").localizedDescription) == "Invalid directory: /abc"
        expect(VoodooError.templateRenderingFailure("xxx").localizedDescription) == "xxx"
        expect(VoodooError.noPortAvailable(8080, 8090).localizedDescription) == "No port available in range 8080 - 8090"
        expect(VoodooError.unexpectedError(TestError.x).localizedDescription) == "The operation couldn’t be completed. (VoodooTests.TestError error 0.)"
        expect(VoodooError.javascriptError("error").localizedDescription) == "error"
        expect(VoodooError.configLoadFailure("failed").localizedDescription) == "failed"
        expect(VoodooError.invalidConfigPath("/abc").localizedDescription) == "Invalid config path /abc"
    }
}
