import Foundation

/// A useful type alias when dealing with HTTP headers.
public typealias HTTPHeaders = [String: String]

public extension [String: String] {

    /// Initialises a ``Headers`` instance with a content type.
    init(contentType: HTTPHeader.ContentType) {
        self.init()
        self[HTTPHeader.contentType] = contentType.contentType
    }
}
