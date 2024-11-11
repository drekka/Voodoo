@testable import Voodoo
import Testing

@Suite("Cache tests")
struct NewCacheTests {

    private let cache: Cache

    init() {
        cache = Cache()
    }

    @Test("Converting to a dictionary", .tags(.cache))
    func dictionaryRepresentation() {
        cache["abc"] = "def"
        let rep = cache.dictionaryRepresentation()
        #expect(rep.count == 1)
        #expect(rep["abc"] as? String == "def")
    }

    @Test("Setting and getting a value via subscript", .tags(.cache))
    func subscriptGetSet() {
        cache["abc"] = "def"
        #expect(cache["abc"] == "def")
    }

    @Test("Setting and getting a value via dunamic lookup", .tags(.cache))
    func dynamicGetSet() {
        cache.abc = "def"
        #expect(cache.abc == "def")
    }

    @Test("Setting a nil removes entry", .tags(.cache))
    func subscriptSettingNilRemovesValue() {
        cache["abc"] = "def"
        #expect(cache["abc"] == "def")
        cache["abc"] = nil
        #expect(cache["abc"] == nil)
    }

    @Test("Setting a nil via dynamic lookup removes entry", .tags(.cache))
    func dynamicLookupSettingNilRemovesValue() {
        cache.abc = "def"
        #expect(cache.abc == "def")
        cache.abc = nil
        #expect(cache.abc == nil)
    }

    @Test("Removing", .tags(.cache))
    func remove() {
        cache.abc = "def"
        #expect(cache.abc == "def")
        cache.remove("abc")
        #expect(cache.abc == nil)
    }
}
