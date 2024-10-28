/// Protocol for types that can store data between requests.
@dynamicMemberLookup
public protocol Cache: AnyObject {

    /// Returns the cache as a dictionary.
    func dictionaryRepresentation() -> [String: Any]

    /// Removes the key the store.
    func remove(_ key: String)

    /// Key based access to stored data.
    subscript<Value>(_: String) -> Value? { get }

    /// Dynamic lookup access to stored data.
    subscript<Value>(dynamicMember _: String) -> Value? { get }

    /// Base subscript for accessing and storing cache values.
    ///
    /// Subscript that supports setting `nil` without having to cast to a type.
    subscript(_: String) -> Any? { get set }

    /// Dynamic lookup access to stored data.
    ///
    /// This subscript supports setting `nil` without having to cast to a type.
    subscript(dynamicMember _: String) -> Any? { get set }
}

/// In memory only cache based around a simple dictionary.
class InMemoryCache: Cache {

    private var cache: [String: Any] = [:]

    subscript<Value>(key: String) -> Value? { self[key] as? Value }

    subscript<Value>(dynamicMember key: String) -> Value? { self[key] as? Value }

    subscript(key: String) -> Any? {
        get { get(key) }
        set { set(newValue, forKey: key) }
    }

    subscript(dynamicMember key: String) -> Any? {
        get { get(key) }
        set { set(newValue, forKey: key) }
    }

    func dictionaryRepresentation() -> [String: Any] { cache }

    func remove(_ key: String) { cache.removeValue(forKey: key) }

    // MARK: - Support functions

    private func get(_ key: String) -> Any? { cache[key] }
    private func set(_ value: Any?, forKey key: String) {
        if let value {
            cache[key] = value
        } else {
            remove(key)
        }
    }
}
