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

        // Bail if the path is not the admin path or there is no command.
        guard let admin = adminPath.popFirst(),
              admin == AdminConsole.adminRoot,
              let command = adminPath.popFirst()
        else {
            return next.respond(to: request)
        }

        switch command {

        case AdminConsole.shutdown where request.method == .POST:
            print("👻 Received shutdown request, shutting down server ...")
            request.application.stop()
            return request.success(HBResponse(status: .ok))

        default:
            return request.success(HBResponse(status: .notFound))
        }
    }
}
