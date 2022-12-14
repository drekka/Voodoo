//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
@testable import Hummingbird
import NIOHTTP1
@testable import Voodoo

extension HBRequest {

    static func mock(_ method: HTTPMethod = .GET,
                     path: String = "/abc",
                     pathParameters: [String: String]? = nil,
                     query: String? = nil,
                     headers: [(String, String)]? = [],
                     contentType: String? = nil,
                     body: String = "") -> HBRequest {

        var components = URLComponents(string: "http://127.0.0.1:8080")!
        components.path = path
        components.query = query
        var hbHeaders = HTTPHeaders(dictionaryLiteral: ("host", "127.0.0.1:8080"))
        headers?.forEach { hbHeaders.add(name: $0.0, value: $0.1) }
        if let contentType {
            hbHeaders.add(name: "Content-Type", value: contentType)
        }

        let head = HTTPRequestHead(version: .http1_1, method: method, uri: components.url!.absoluteString, headers: hbHeaders)
        let application = HBApplication()
        application.delay = 0.0
        let context = MockHBRequestContext()
        var hbRequest = HBRequest(head: head, body: body.hbRequestBody, application: application, context: context)

        var hbParameters = HBParameters()
        pathParameters?.forEach { hbParameters.set(Substring($0), value: Substring($1)) }
        hbRequest.parameters = hbParameters

        return hbRequest
    }
}
