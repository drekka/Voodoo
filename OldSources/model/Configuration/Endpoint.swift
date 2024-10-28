import Foundation

/// An endpoint defines a mocked API.
///
/// This no property protocol is so we can pass around mixed lists of end points.
public protocol Endpoint: Decodable {

    /// Returns true if the ``Endpoint`` can be decoded from the passed decoder.
    static func canDecode(from decoder: Decoder) throws -> Bool
}
