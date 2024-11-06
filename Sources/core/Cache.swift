
import Foundation

/// In memory only cache based around a simple dictionary.
@dynamicMemberLookup
public class Cache {
    private var cache: [String: Any] = [:]

    /// Key based access to stored data.
    public subscript<Value>(key: String) -> Value? { self[key] as? Value }

    /// Dynamic lookup access to stored data.
    public subscript<Value>(dynamicMember key: String) -> Value? { self[key] as? Value }

    /// Base subscript for accessing and storing cache values.
    ///
    /// Subscript that supports setting `nil` without having to cast to a type.
    public subscript(key: String) -> Any? {
        get { get(key) }
        set { set(newValue, forKey: key) }
    }

    /// Dynamic lookup access to stored data.
    ///
    /// This subscript supports setting `nil` without having to cast to a type.
    public subscript(dynamicMember key: String) -> Any? {
        get { get(key) }
        set { set(newValue, forKey: key) }
    }

    /// Returns the cache as a dictionary.
    func dictionaryRepresentation() -> [String: Any] { cache }

    /// Removes the key the store.
    public func remove(_ key: String) { cache.removeValue(forKey: key) }

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
