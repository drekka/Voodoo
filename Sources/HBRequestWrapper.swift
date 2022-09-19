//
//  Created by Derek Clarkson on 6/8/2022.
//

import Foundation
import Hummingbird

/// Thin wrapper around the core Hummingbird request that provides some additional processing.
struct HBRequestWrapper: HTTPRequest {

    struct HBQueryParametersWrapper: QueryParameters {
        let parameters: HBParameters
        subscript(key: String) -> String? { parameters[key] }
        subscript(key: String) -> [String] { parameters.getAll(key) }
    }

    let request: HBRequest

    var method: HTTPMethod { request.method }

    var headers: Headers { Dictionary(request.headers.map { ($0, $1) }) { $1 } }

    var path: String { request.uri.path }

    var pathParameters: PathParameters { Dictionary(request.parameters.map { (String($0.key), String($0.value)) }) { $1 } }

    var query: String? { request.uri.query }

    var queryParameters: QueryParameters { HBQueryParametersWrapper(parameters: request.uri.queryParameters) }

    var body: Data? {
        let bodyLength = request.body.buffer?.readableBytes ?? 0
        return request.body.buffer?.getData(at: 0, length: bodyLength)
    }

    var bodyJSON: Any? {
        guard request.headers["Content-Type"].first == "application/json",
              let buffer = request.body.buffer else { return nil }
        return try? JSONSerialization.jsonObject(with: buffer)
    }

    var formParameters: FormParameters {

        guard request.headers["Content-Type"].first == "application/x-www-form-urlencoded",
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
