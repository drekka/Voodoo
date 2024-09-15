import Foundation

/// Code completion and keys for common HTTP headers.
public enum HTTPHeader {

    public static let contentType = "content-type"
    public static let location = "location"

    public struct ContentType {

        public static let textPlain = ContentType(contentType: "text/plain")
        public static let textHTML = ContentType(contentType: "text/html")
        public static let applicationJSON = ContentType(contentType: "application/json")
        public static let applicationYAML = ContentType(contentType: "application/yaml")
        public static let applicationGraphQL = ContentType(contentType: "application/graphql")
        public static let applicationFormData = ContentType(contentType: "application/x-www-form-urlencoded")
        public static let applicationMarkdown = ContentType(contentType: "application/markdown")

        let contentType: String

        public static func other(_ contentType: String) -> ContentType {
            ContentType(contentType: contentType.lowercased())
        }
    }
}

extension HTTPHeader.ContentType: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.contentType = try container.decode(String.self)
    }
}

extension HTTPHeader.ContentType: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.contentType == rhs.contentType
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.contentType == rhs.lowercased()
    }

    public static func == (lhs: String, rhs: Self) -> Bool {
        lhs.lowercased() == rhs.contentType
    }

    public static func == (lhs: Self, rhs: String?) -> Bool {
        lhs.contentType == rhs?.lowercased()
    }

    public static func == (lhs: String?, rhs: Self) -> Bool {
        lhs?.lowercased() == rhs.contentType
    }
}

