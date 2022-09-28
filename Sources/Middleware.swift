//
//  Created by Derek Clarkson on 16/9/2022.
//

import Foundation
import Hummingbird

/// Captures the incoming requests "host" header for injecting as the mock server URL.
struct HostCapture: HBMiddleware {
    func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        let host = request.headers.first(name: "host") ?? "127.0.0.1:\(request.application.address.port ?? 80)"
        request.application.cache["mockServer"] = "http://" + host
        return next.respond(to: request)
    }
}

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

/// Logs an error when no response is found for a request.
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
