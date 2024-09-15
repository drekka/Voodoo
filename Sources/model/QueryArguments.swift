import Foundation

/// Protocol that provides dynamic lookup on dictionaries.
@dynamicMemberLookup
public protocol DynamicQueryArguments {
    subscript(dynamicMember _: String) -> String? { get }
    subscript(dynamicMember _: String) -> [String] { get }
}

extension [(String, String)]: DynamicQueryArguments {

    public subscript(dynamicMember key: String) -> String? {
        first { $0.0 == key }?.1
    }

    public subscript(dynamicMember key: String) -> [String] {
        filter { $0.0 == key }.map(\.1)
    }
}
