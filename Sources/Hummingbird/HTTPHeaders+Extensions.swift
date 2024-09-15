import Foundation
import Hummingbird

extension Hummingbird.HTTPHeaders: DynamicQueryArguments {

    public var uniqueKeys: [String] {
        var hashes = Set<Int>()
        return compactMap { hashes.insert($0.name.hashValue).inserted ? $0.name : nil }
    }

    public mutating func add(contentType: HTTPHeader.ContentType) {
        add(name: HTTPHeader.contentType, value: contentType.contentType)
    }

    public subscript(key: String) -> String? { first(name: key) }

    public subscript(dynamicMember key: String) -> String? { first(name: key) }

    public subscript(dynamicMember key: String) -> [String] { self[key] }
}
