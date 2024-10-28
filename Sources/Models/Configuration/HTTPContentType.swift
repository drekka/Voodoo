import Foundation

/// Protocol defining sources of content type strings.
public protocol HTTPContentTypeProvider {
    var rawValue: String { get }
}

/// Predefined content types.
public enum HTTPContentType: String, HTTPContentTypeProvider {
    case applicationJSON = "application/json"
    case applicationYAML = "application/yaml"
    case textPlain = "text/plain"
}

/// Allows any string to become a content type.
extension String: HTTPContentTypeProvider {
    public var rawValue: String { self }
}
