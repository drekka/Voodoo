//
//  Created by Derek Clarkson on 6/8/2022.
//

/// Protocol for types that can store data between requests.
@dynamicMemberLookup
public protocol Cache: AnyObject {

    /// Returns the cache as a dictionary.
    func dictionaryRepresentation() -> [String: Any]

    /// Removes the key the store.
    func remove(_ key: String)

    /// Key based access to stored data.
    ///
    /// Passing a `nil` will remove a value the same as using ``remove(_:)``.
    subscript<Value>(_: String) -> Value? { get set }

    /// Subscript that supports setting `nil` without having to cast to a type.
    subscript(_: String) -> Any? { get set }

    /// Dynamic lookup access to stored data.
    ///
    /// This passes through to ``subscript(_:)-4d6z6``.
    subscript<Value>(dynamicMember _: String) -> Value? { get set }

    /// Dynamic lookup access to stored data.
    ///
    /// This subscript supports setting `nil` without having to cast to a type.
    /// This passes through to ``subscript(_:)-8jok5``.
    subscript(dynamicMember _: String) -> Any? { get set }
}

/// In memory only cache based around a simple dictionary.
class InMemoryCache: Cache {

    private var cache: [String: Any] = [:]

    subscript<Value>(dynamicMember key: String) -> Value? {
        get { get(key) }
        set { set(newValue, forKey: key) }
    }

    subscript<Value>(key: String) -> Value? {
        get { get(key) }
        set { set(newValue, forKey: key) }
    }

    subscript(key: String) -> Any? {
        get { get(key) as Any? }
        set { set(newValue, forKey: key) }
    }

    func dictionaryRepresentation() -> [String: Any] { cache }

    func remove(_ key: String) { cache.removeValue(forKey: key) }

    // MARK: - Support functions

    private func get<Value>(_ key: String) -> Value? { cache[key] as? Value }
    private func set<Value>(_ value: Value?, forKey key: String) {
        if let value = value {
            cache[key] = value
        } else {
            remove(key)
        }
    }
}
