import Foundation

/// Protocol that provides dynamic lookup on dictionaries.
@dynamicMemberLookup
public protocol DynamicDictionary {
    associatedtype Key: ExpressibleByStringLiteral
    associatedtype Value
    subscript(dynamicMember _: Key) -> Value? { get set }
}

/// Adds dynamic lookup to all dictionaries using string keys.
extension Dictionary: DynamicDictionary where Key: ExpressibleByStringLiteral {

    public subscript(dynamicMember member: Key) -> Value? {
        get {
            self[member]
        }
        set {
            self[member] = newValue
        }
    }
}


