//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import GraphQL
import Hummingbird

/// Logs all incoming requests.
struct RequestLogger: HBMiddleware {

    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        voodooLog("Received \(request.method) \(request.uri)") 
        return next.respond(to: request)
    }
}

/// Logs errors coming back from the routers.
public struct NoResponseFoundMiddleware: HBMiddleware {

    public func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        next.respond(to: request)
            .flatMapError { error in
                switch error {
                case let error as GraphQLError:
                    voodooLog("⚠️ Voodoo GraphQL error: \(error)")
                    return request.failure(VoodooError.invalidGraphQLRequest(error.description))
                case let error as VoodooError:
                    voodooLog("⚠️ Voodoo error: \(error.localizedDescription)")
                case let error as HBHTTPError where error.status == .notFound:
                    let signature = "\(request.method) \(request.uri.path)"
                    voodooLog("⚠️ No endpoint registered for: \(signature)")
                    return request.failure(VoodooError.noHTTPEndpoint("No endpoint registered for: \(signature)"))
                default:
                    voodooLog("⚠️ Unexpected error: \(error.localizedDescription)")
                }
                return request.failure(error)
            }
    }
}
