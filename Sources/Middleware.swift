//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import Hummingbird

/// Logs all incoming requests.
struct RequestLogger: HBMiddleware {
    let verbose: Bool
    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        if verbose {
            print("👻 Received \(request.method) \(request.uri)")
        }
        return next.respond(to: request)
    }
}

public struct NoResponseFoundMiddleware: HBMiddleware {
    public func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        next.respond(to: request).map { $0 }
            .flatMapError { error in
                if let error = error as? HBHTTPError, error.status == .notFound {
                    print("👻 ⚠️ No endpoint registered for: \(request.method) \(request.uri.path)")
                }
                return request.failure(error)
            }
    }
}
