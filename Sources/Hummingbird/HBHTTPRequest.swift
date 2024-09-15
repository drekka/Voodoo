import AnyCodable
import Foundation
import Hummingbird
import Yams

/// Wrapper around Hummingbirds request that translates it's API into Voodoo's.
///
/// This had to be done as a wrapper due to various properties which needed to have the same
/// names but different types.
struct HBHTTPRequest: HTTPRequest {

    let request: Hummingbird.HBRequest

    public var headers: [String: String] {
        request.headers
    }

    public var pathArguments: [String:String] {
        request.
    }

    public var queryArguments: [(String, String)] {}

    public var body: Data? {}

    public var formParameters: [String: String] {}

    public var path: String { uri.path }

    public var pathComponents: [String] { uri.path.split(separator: "/").map { String($0) } }

    public var pathParameters: [String: String] {
        // hummingbird will fatal if there are no parameters and we try to access them.
        guard extensions.exists(\.parameters) else { return [:] }
        return Dictionary(parameters.map { (String($0.key), String($0.value)) }) { $1 }
    }

    public var query: String? { uri.query }

    public var queryParameters: KeyedValues { uri.queryParameters }

    public var bodyJSON: Any? {
        guard contentType(is: .applicationJSON),
              let buffer = body.buffer else { return nil }
        return try? JSONSerialization.jsonObject(with: buffer)
    }

    public var bodyYAML: Any? {
        guard contentType(is: .applicationYAML),
              let data = body.buffer?.data else { return nil }
        return try? YAMLDecoder().decode(AnyDecodable.self, from: data).value
    }

    public var formParameters: [String: String] {

        guard contentType(is: .applicationFormData),
              let data = body.buffer?.data else {
            return [:]
        }

        // Forms come in using encoding that's the same as that used for URL query arguments.
        // So we'll use the same logic to decode them.
        let rawFormData = String(data: data, encoding: .utf8)
        var components = URLComponents()
        components.percentEncodedQuery = rawFormData

        guard let items = components.queryItems else { return [:] }

        return Dictionary(items.compactMap {
            guard !$0.name.isEmpty,
                  let value = $0.value?.removingPercentEncoding?.replacingOccurrences(of: "+", with: " ")
            else {
                return nil
            }
            return ($0.name, value)
        }) { $1 }
    }

    public var graphQLRequest: GraphQLRequest? {
        try? GraphQLRequest(request: self)
    }

    public func contentType(is contentType: HTTPHeader.ContentType) -> Bool {
        headers[HTTPHeader.contentType] == contentType
    }

    func decodeBodyJSON<T>(as type: T.Type) -> T? where T: Decodable {
        guard contentType(is: HTTPHeader.ContentType.applicationJSON),
              let buffer = body.buffer else { return nil }
        return try? JSONDecoder().decode(type, from: buffer)
    }
}
