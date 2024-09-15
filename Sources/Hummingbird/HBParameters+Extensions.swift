import Foundation
import Hummingbird

/// Applies ``KeyedValues`` to Hummingbird's parameters.
extension HBParameters: KeyedValues {

    public var uniqueKeys: [String] {
        var hashes = Set<Int>()
        return compactMap { hashes.insert($0.key.hashValue).inserted ? String($0.key) : nil }
    }

    public subscript(key: String) -> [String] { getAll(key) }

    public subscript(dynamicMember key: String) -> String? { self[key] }

    public subscript(dynamicMember key: String) -> [String] { getAll(key) }
}
