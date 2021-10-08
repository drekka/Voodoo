//
//  Created by Derek Clarkson on 30/9/21.
//

import Swifter

/// Defines sources of `MockEndPoint` definitions.
protocol RegisterableAPI {
    func register(onServer server: HttpServer, errorHandler: @escaping (HttpRequest, Error) -> HttpResponse)
}

// MARK: - Implementation

extension RegisterableAPI {
    
    /// Internal function for registering mock API responses.
    ///
    /// This function provides the core processing using the passed arguments as inputs.
    func register(onServer server: HttpServer,
                  method: HTTPMethod,
                  pathTemplate: String,
                  response: @escaping @autoclosure () throws -> HTTPResponse,
                  errorHandler: @escaping (HttpRequest, Error) -> HttpResponse) {
        var router = method.router(for: server)
        router.addRoute(path: pathTemplate) { request in
            do {
                log.debug("🧞‍♂️ MockEndpoint: Responding to request \(request.method) \(request.path)")
                return try response().asSwifterResponse(forRequest: request)
            } catch {
                log.debug("🧞‍♂️ MockEndpoint: Error detected \(error.localizedDescription)")
                return errorHandler(request, error)
            }
        }
    }
}
