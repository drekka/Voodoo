//
//  Created by Derek Clarkson on 6/8/2022.
//

import Foundation
import Hummingbird
import NIOCore
import NIOFoundationCompat

extension String {

    /// The same effect as ``URL.pathComponents`` property but assuming the string is a path.
    var urlPathComponents: [String.SubSequence] {
        ["/"] + split(separator: "/")
    }
}

extension HBRequest {

    /// Convenience variable to obtain a wrapped request.
    var asHTTPRequest: HTTPRequest {
        HBRequestWrapper(request: self)
    }
}

extension HTTPHeaders: KeyedValues {

    public var uniqueKeys: [String] {
        var hashes = Set<Int>()
        return compactMap { hashes.insert($0.name.hashValue).inserted ? $0.name : nil }
    }

    public subscript(key: String) -> String? { first(name: key) }
}

extension HBParameters: KeyedValues {

    public var uniqueKeys: [String] {
        var hashes = Set<Int>()
        return compactMap { hashes.insert($0.key.hashValue).inserted ? String($0.key) : nil }
    }


    public subscript(key: String) -> [String] {
        getAll(key)
    }
}

/// Thin wrapper around the core Hummingbird request that provides some additional processing.
struct HBRequestWrapper: HTTPRequest {

    /// The wrapped Hummingbird request.
    let request: HBRequest

    var method: HTTPMethod { request.method }

    var headers: KeyedValues { request.headers }

    var path: String { request.uri.path }

    var pathComponents: [String] { request.uri.path.urlPathComponents.map { String($0) } }

    var pathParameters: [String: String] { Dictionary(request.parameters.map { (String($0.key), String($0.value)) }) { $1 } }

    var query: String? { request.uri.query }

    var queryParameters: KeyedValues { request.uri.queryParameters }

    var body: Data? { return request.body.buffer?.data }

    var bodyJSON: Any? {
        guard request.headers[ContentType.key].first == ContentType.applicationJSON,
              let buffer = request.body.buffer else { return nil }
        return try? JSONSerialization.jsonObject(with: buffer)
    }

    var formParameters: [String: String] {

        guard request.headers[ContentType.key].first == ContentType.applicationFormData,
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
}
