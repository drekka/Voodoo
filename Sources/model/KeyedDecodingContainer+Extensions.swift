import Foundation
import AnyCodable

/// Extension of common fields we can extract from a decoding container.
extension KeyedDecodingContainer where Key == HTTPResponse.Body.CodingKeys {

    /// Decode the content type from the keyed container using the content type key.
    var contentType: HTTPHeader.ContentType {
        get throws {
            guard let contentType = try decodeIfPresent(HTTPHeader.ContentType.self, forKey: .contentType) else {
                return .applicationJSON
            }
            return contentType
        }
    }

    /// Decode any template data, assuming it's a dictionary of some form.
    var templateData: [String: Any]? {
        get throws {
            try decodeIfPresent(AnyCodable.self, forKey: .templateData)?.value as? [String: Any]
        }
    }
}

