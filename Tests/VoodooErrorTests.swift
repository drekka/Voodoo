//
//  Created by Derek Clarkson on 11/10/2022.
//

import Nimble
import Voodoo
import XCTest

class VoodooErrorTests: XCTestCase {

    func testMessages() {
        expect(VoodooError.directoryNotExists("/abc").headers.first(name: VoodooError.headerKey)) == "Missing or URL was not a directory: /abc"
        expect(VoodooError.templateRenderingFailure("xxx").headers.first(name: VoodooError.headerKey)) == "xxx"
        expect(VoodooError.noPortAvailable.headers.first(name: VoodooError.headerKey)) == "All ports taken."
        expect(VoodooError.unexpectedError(VoodooError.noPortAvailable).headers.first(name: VoodooError.headerKey)) == "The operation couldn’t be completed. (Voodoo.VoodooError error 7.)"
        expect(VoodooError.javascriptError("error").headers.first(name: VoodooError.headerKey)) == "error"
        expect(VoodooError.configLoadFailure("failed").headers.first(name: VoodooError.headerKey)) == "failed"
        expect(VoodooError.invalidConfigPath("/abc").headers.first(name: VoodooError.headerKey)) == "Invalid config path /abc"
        expect(VoodooError.directoryNotExists("/abc").headers.first(name: VoodooError.headerKey)) == "Missing or URL was not a directory: /abc"
    }
}
