//
//  Created by Derek Clarkson on 6/8/2022.
//

import AnyCodable
import Foundation
import Hummingbird
import NIOCore
import Yams

/// Thin wrapper around the core Hummingbird request that provides some additional processing.
struct HBRequestWrapper: HTTPRequest {

    /// The wrapped Hummingbird request.
    let request: HBRequest

    var method: HTTPMethod { request.method }

    var headers: KeyedValues { request.headers }

    var path: String { request.uri.path }

    var pathComponents: [String] { request.uri.path.urlPathComponents.map { String($0) } }

    var pathParameters: [String: String] {
        // humming bird will fatal if there are no parameters and we try to access them.
        guard request.extensions.exists(\.parameters) else { return [:] }
        return Dictionary(request.parameters.map { (String($0.key), String($0.value)) }) { $1 }
    }

    var query: String? {
        request.uri.query
    }

    var queryParameters: KeyedValues { request.uri.queryParameters }

    var body: Data? { return request.body.buffer?.data }

    var bodyJSON: Any? {
        guard contentType(is: Header.ContentType.applicationJSON),
              let buffer = request.body.buffer else { return nil }
        return try? JSONSerialization.jsonObject(with: buffer)
    }

    var bodyYAML: Any? {
        guard contentType(is: Header.ContentType.applicationYAML),
              let data = request.body.buffer?.data else { return nil }
        return try? YAMLDecoder().decode(AnyDecodable.self, from: data).value
    }

    var formParameters: [String: String] {

        guard contentType(is: Header.ContentType.applicationFormData),
              let buffer = request.body.buffer else { return [:] }

        // Forms come in using encoding that's the same as that used for URL query arguments.
        // So we'll use the same logic to decode them.
        let rawFormData = String(buffer: buffer)
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

    var graphQLRequest: GraphQLRequest? {
        return try? GraphQLRequest(request: self)
    }

    /// Helper for analysing the content type of a request.
    func contentType(is contentType: String) -> Bool {
        headers[Header.contentType]?.contains(contentType) ?? false
    }
}

// MARK: - Supporting extensions

extension String {

    /// The same effect as ``URL.pathComponents`` property but assuming the string is a path.
    var urlPathComponents: [String.SubSequence] {
        ["/"] + split(separator: "/")
    }
}

