import Foundation
import NIOCore
import NIOHTTP1

extension ByteBuffer {

    /// Convenience property for returning the contents of the buffer as `Data`.
    var data: Data? {
        getData(at: 0, length: readableBytes)
    }
}

/// Make the HTTP method decodable from YAML files.
extension HTTPMethod: @retroactive Decodable {

    /// Decodes a `HTTPMethod` from a coder in a case-insensitive manner.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawMethod = try container.decode(String.self)
        self = HTTPMethod(rawValue: rawMethod.uppercased())
    }
}
