//
//  File.swift
//
//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import Hummingbird
import System

struct AdminConsole: HBMiddleware, CustomStringConvertible {

    private let adminRoot: FilePath = "/_admin"
    private let shutdown: FilePath = "shutdown"

    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {

        let pathComponents = request.uri.path.split(separator: "/")
        var adminPath = FilePath(request.uri.path)

        // Bail if the path is not an admin path and if it is, remove the admin component.
        guard adminPath.removePrefix(adminRoot) else {
            return next.respond(to: request)
        }

        switch adminPath {

        case shutdown:
            print("👻 Received shutdown request, shutting down server ...")
            request.application.stop()
            return request.success(HBResponse(status: .ok))

        default:
            return request.success(HBResponse(status: .notFound))
        }
    }

    var description: String {
        adminRoot.pushing(shutdown).string
    }
}
