//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
@testable import Hummingbird

enum MockRequest {

    static func create(url: String,
                       pathParameters: [String: String] = [:],
                       headers: [String: String] = [:],
                       contentType: String? = nil,
                       body: String = "") -> HBRequest
    {

        var hbHeaders = HTTPHeaders()
        headers.forEach { hbHeaders.add(name: $0, value: $1) }
        if let contentType = contentType {
            hbHeaders.add(name: "Content-Type", value: contentType)
        }

        let head = HTTPRequestHead(version: .http1_1, method: .GET, uri: url, headers: hbHeaders)

        let byteBuffer = ByteBuffer(string: body)
        let body = HBRequestBody.byteBuffer(byteBuffer)

        let application = HBApplication()
        let context = MockContext()
        var hbRequest = HBRequest(head: head, body: body, application: application, context: context)

        var hbParameters = HBParameters()
        pathParameters.forEach { hbParameters.set(Substring($0), value: Substring($1)) }
        hbRequest.parameters = hbParameters

        return hbRequest
    }
}
