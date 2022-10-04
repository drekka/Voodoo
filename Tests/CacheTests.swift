//
//  Created by Derek Clarkson on 15/9/2022.
//

import Foundation
import Nimble
@testable import SimulcraCore
import XCTest

class CacheTests: XCTestCase {

    private var cache: Cache!

    override func setUp() {
        super.setUp()
        cache = InMemoryCache()
    }

    func testDictionaryRepresentation() {
        cache["abc"] = "def"
        let rep = cache.dictionaryRepresentation()
        expect(rep.count) == 1
        expect(rep["abc"] as? String) == "def"
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

    func testRemove() {
        cache.abc = "def"
        expect(self.cache.abc) == "def"
        cache.remove("abc")
        expect(self.cache.abc).to(beNil())
    }
}
