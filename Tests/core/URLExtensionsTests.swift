//
//  Created by Derek Clarkson on 10/10/2022.
//

import Foundation
import Nimble
@testable import Voodoo
import XCTest

class URLExtensionsTests: XCTestCase {

    func testFileExistsWithValidFile() {
        let url = Bundle.testBundle.url(forResource: "files/Simple", withExtension: "json")!
        expect(url.fileSystemStatus) == .file
    }

    func testFileExistsWithInValidFile() {
        let url = URL(fileURLWithPath: "/abc/def")
        expect(url.fileSystemStatus) == .notFound
    }

    func testFileExistsWithDirectory() {
        let url = Bundle.testBundle.url(forResource: "files", withExtension: nil)!
        expect(url.fileSystemStatus) == .directory
    }
}
