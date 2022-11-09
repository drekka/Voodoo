//
//  Created by Derek Clarkson on 11/10/2022.
//

import Nimble
import Voodoo
import XCTest

class VoodooErrorTests: XCTestCase {

    func testMessages() {
        expect(VoodooError.directoryNotExists("/abc").localizedDescription) == "Missing or URL was not a directory: /abc"
        expect(VoodooError.templateRenderingFailure("xxx").localizedDescription) == "xxx"
        expect(VoodooError.noPortAvailable.localizedDescription) == "All ports taken."
        expect(VoodooError.unexpectedError(VoodooError.noPortAvailable).localizedDescription) == "The operation couldn’t be completed. (Voodoo.VoodooError error 7.)"
        expect(VoodooError.javascriptError("error").localizedDescription) == "error"
        expect(VoodooError.configLoadFailure("failed").localizedDescription) == "failed"
        expect(VoodooError.invalidConfigPath("/abc").localizedDescription) == "Invalid config path /abc"
        expect(VoodooError.directoryNotExists("/abc").localizedDescription) == "Missing or URL was not a directory: /abc"
    }
}
