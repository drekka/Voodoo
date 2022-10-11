//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
@testable import Hummingbird
@testable import SimulcraCore

extension HBRequest {

    static let mockHost = "127.0.0.1"
    static let mockServer = "\(mockHost):8080"
    static let mockServerRequestURL = "http://\(mockServer)/abc"

    static func mock(_ method: HTTPMethod = .GET,
                     url: String = mockServerRequestURL,
                     pathParameters: [String: String]? = nil,
                     headers: [String: String]? = ["host": mockServer],
                     contentType: String? = nil,
                     body: String = "") -> HBRequest {

        var hbHeaders = HTTPHeaders()
        headers?.forEach { hbHeaders.add(name: $0, value: $1) }
        if let contentType {
            hbHeaders.add(name: "Content-Type", value: contentType)
        }

        let head = HTTPRequestHead(version: .http1_1, method: method, uri: url, headers: hbHeaders)

        let body = body.hbRequestBody

        let application = HBApplication()
        let context = MockHBRequestContext()
        var hbRequest = HBRequest(head: head, body: body, application: application, context: context)

        var hbParameters = HBParameters()
        pathParameters?.forEach { hbParameters.set(Substring($0), value: Substring($1)) }
        hbRequest.parameters = hbParameters

        return hbRequest
    }
}
