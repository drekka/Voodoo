import Foundation
import Nimble
@testable import Voodoo
import XCTest

class CacheTests: XCTestCase {

    private var cache: Cache!

    override func setUp() {
        super.setUp()
        cache = Cache()
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
