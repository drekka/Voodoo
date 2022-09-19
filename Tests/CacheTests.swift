//
//  Created by Derek Clarkson on 15/9/2022.
//

import Foundation
import Nimble
@testable import Simulcra
import XCTest

class CacheTests: XCTestCase {

    private var cache: Cache!

    override func setUp() {
        super.setUp()
        cache = InMemoryCache()
    }

    func testGetSetValue() {
        cache["abc"] = "def"
        expect(self.cache["abc"]) == "def"
    }

    func testGetSetValueViaDynamicName() {
        cache.abc = "def"
        expect(self.cache.abc) == "def"
    }

    func testSettingNilRemovesValue() {
        cache["abc"] = "def"
        expect(self.cache["abc"]) == "def"
        cache["abc"] = nil
        expect(self.cache["abc"]).to(beNil())
    }

    func testSettingNilRemovesValueViaDynamicName() {
        cache.abc = "def"
        expect(self.cache.abc) == "def"
        cache.abc = nil
        expect(self.cache.abc).to(beNil())
    }
}
