//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import GraphQL
import Hummingbird

/// Logs all incoming requests.
struct RequestLogger: HBMiddleware {
    let verbose: Bool
    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        if verbose {
            print("💀 Received \(request.method) \(request.uri)")
        }
        return next.respond(to: request)
    }
}

/// Logs an error when no response is found for a request.
public struct NoResponseFoundMiddleware: HBMiddleware {
    public func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        next.respond(to: request)
            .flatMapError { error in
                switch error {
                case let error as GraphQLError:
                    print("💀 ⚠️ Voodoo GraphQL error: \(error)")
                    return request.failure(VoodooError.invalidGraphQLRequest(error.description))
                case let error as VoodooError:
                    print("💀 ⚠️ Voodoo error: \(error.localizedDescription)")
                case let error as HBHTTPError where error.status == .notFound:
                    let signature = "\(request.method) \(request.uri.path)"
                    print("💀 ⚠️ No endpoint registered for: \(signature)")
                    return request.failure(VoodooError.noHTTPEndpoint("No endpoint registered for: \(signature)"))
                default:
                    print("💀 ⚠️ Unexpected error: \(error.localizedDescription)")
                }
                return request.failure(error)
            }
    }
}
