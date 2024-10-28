import Foundation

/// HTTP headers.
public enum HTTPHeader {

    case contentType(HTTPContentTypeProvider)
    case location(URL)
    case other(String, String)

    init(keyValue: (key: String, value: String)) throws(VoodooError) {
        let key = keyValue.key.lowercased()
        if key == "content-type", let contentType = HTTPContentType(rawValue: keyValue.key) {
            self = .contentType(contentType)
        } else if key == "location" {
            guard let location = URL(string: keyValue.value) else {
                throw VoodooError.invalidHeaderLocationURL(keyValue.value)
            }
            self = .location(location)
        } else {
            self = .other(key, keyValue.value)
        }
    }

    /// The key of the header.
    var keyValue: (key: String, value: String) {
        switch self {
        case .contentType(let contentType):
            (key: "Content-Type", value: contentType.rawValue)
        case .location(let location):
            (key: "Location", value: location.absoluteString)
        case .other(let key, let value):
            (key: key, value: value)
        }
    }
}

/// Headers are stored in a set to ensure there can only be one value for each header, therefore
/// we only hash and equate the keys to ensure they're unique based on that.
extension HTTPHeader: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(keyValue.key)
    }

    public static func == (lhs: HTTPHeader, rhs: HTTPHeader) -> Bool {
        lhs.keyValue.key == rhs.keyValue.key
    }
}
