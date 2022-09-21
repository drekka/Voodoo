//
//  Created by Derek Clarkson on 6/8/2022.
//

import Foundation
import Hummingbird

extension String {

    /// The same effect as ``URL``s `pathComponents` property but assuming the string is a path.
    var urlPathComponents: [String.SubSequence] {
        ["/"] + self.split(separator: "/")
    }
}

/// Thin wrapper around the core Hummingbird request that provides some additional processing.
struct HBRequestWrapper: HTTPRequest {

    struct HBQueryParametersWrapper: QueryParameters {
        let parameters: HBParameters
        subscript(key: String) -> String? { parameters[key] }
        subscript(key: String) -> [String] { parameters.getAll(key) }
    }

    /// The wrapped Hummingbird request.
    let request: HBRequest

    var method: HTTPMethod { request.method }

    var headers: Headers { Dictionary(request.headers.map { ($0, $1) }) { $1 } }

    var path: String { request.uri.path }

    var pathComponents: [String] { request.uri.path.urlPathComponents.map { String($0) } }

    var pathParameters: PathParameters { Dictionary(request.parameters.map { (String($0.key), String($0.value)) }) { $1 } }

    var query: String? { request.uri.query }

    var queryParameters: QueryParameters { HBQueryParametersWrapper(parameters: request.uri.queryParameters) }

    var body: Data? { return request.body.buffer?.data }

    var bodyJSON: Any? {
        guard request.headers[ContentType.key].first == ContentType.applicationJSON,
              let buffer = request.body.buffer else { return nil }
        return try? JSONSerialization.jsonObject(with: buffer)
    }

    var formParameters: FormParameters {

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
