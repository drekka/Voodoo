//
//  File.swift
//
//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import Hummingbird

struct AdminConsole: HBMiddleware {

    static let adminRoot = "_admin"
    static let shutdown = "shutdown"

    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {

        var adminPath = request.uri.path.urlPathComponents.dropFirst(1)

        // Bail if the path is not an admin path and if it is, remove the admin component.
        guard adminPath.removeFirst() == AdminConsole.adminRoot else {
            return next.respond(to: request)
        }

        switch adminPath.removeFirst() {

        case AdminConsole.shutdown:
            print("👻 Received shutdown request, shutting down server ...")
            request.application.stop()
            return request.success(HBResponse(status: .ok))

        default:
            return request.success(HBResponse(status: .notFound))
        }
    }
}
