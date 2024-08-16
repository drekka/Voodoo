import Foundation

/// A protocol to support applying dynamic member lookup on a dictionary.
///
/// Because dictionaries are frozen we have to go through a protocol to apply @dynamicMemberLookup.
@dynamicMemberLookup
public protocol DictionaryDynamicLookup {
    associatedtype Key
    associatedtype Value
    subscript(_: Key) -> Value? { get }
}

/// Base implementation.
public extension DictionaryDynamicLookup where Key == String {
    subscript(dynamicMember key: String) -> Value? {
        self[key]
    }
}

/// Extension to apply dynamic lookup to dictionaries where the key is a string.
extension Dictionary: DictionaryDynamicLookup where Key == String {}

