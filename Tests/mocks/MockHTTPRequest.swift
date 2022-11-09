//
//  Created by Derek Clarkson on 16/9/2022.
//

import AnyCodable
import Foundation
@testable import Hummingbird
import NIOHTTP1
@testable import Voodoo
import Yams

struct MockHTTPRequest: HTTPRequest {
    let method: HTTPMethod
    let headers: KeyedValues
    let path: String
    let pathComponents: [String]
    let pathParameters: [String: String]
    let query: String?
    let queryParameters: KeyedValues
    let body: Data?
    let bodyJSON: Any?
    let bodyYAML: Any?
    let formParameters: [String: String]
    var graphQLRequest: GraphQLRequest? {
        try! GraphQLRequest(request: self)
    }

    func contentType(is: String) -> Bool {
        true
    }
}

extension HBRequestWrapper {

    static func mock(_ method: HTTPMethod = .GET,
                     path: String = "/abc",
                     pathParameters: [String: String]? = nil,
                     query: String? = nil,
                     headers: [(String, String)]? = [],
                     contentType: String? = nil,
                     body: String = "") -> HTTPRequest {

        var hbHeaders = HTTPHeaders(dictionaryLiteral: ("host", "127.0.0.1:8080"))
        headers?.forEach { hbHeaders.add(name: $0.0, value: $0.1) }
        if let contentType {
            hbHeaders.add(name: "Content-Type", value: contentType)
        }
        let bodyData = body.data(using: .utf8)!
        var components = URLComponents()
        components.query = query
        let queryItems = components.queryItems?.map { ($0.name, $0.value) } ?? []
        let formParameters = Dictionary(queryItems) { $1 }.compactMapValues { $0 }

        return MockHTTPRequest(
            method: method,
            headers: hbHeaders,
            path: path,
            pathComponents: path.urlPathComponents.map { String($0) },
            pathParameters: pathParameters ?? [:],
            query: query,
            queryParameters: [:],
            body: bodyData,
            bodyJSON: try? JSONSerialization.jsonObject(with: bodyData),
            bodyYAML: try? YAMLDecoder().decode(AnyCodable.self, from: bodyData),
            formParameters: formParameters
        )
    }
}

extension [String: String]: KeyedValues {

    public var uniqueKeys: [String] {
        keys.map { $0 }
    }

    public subscript(dynamicMember key: String) -> [String] {
        if let value = self[key] {
            return [value]
        }
        return []
    }

    public subscript(key: String) -> [String] {
        if let value = self[key] {
            return [value]
        }
        return []
    }
}
