import AnyCodable
import Foundation

/// Provides some common properties extracted from the data being decode for a response body.
extension KeyedDecodingContainer where Key == HTTPResponse.Body.CodingKeys {

    /// The content type to apply to the response. Defaults to JSON.
    var decodedContentType: any HTTPContentTypeProvider {
        get throws {
            guard let rawContentType = try decodeIfPresent(String.self, forKey: .contentType) else {
                return HTTPContentType.applicationJSON
            }
            return HTTPContentType(rawValue: rawContentType) ?? rawContentType
        }
    }

    /// Any template data stored in the configuration.
    var decodedTemplateData: [String: Any] {
        get throws {
            try (decodeIfPresent(AnyCodable.self, forKey: .templateData)?.value as? [String: Any]) ?? [:]
        }
    }
}
