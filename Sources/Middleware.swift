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

enum GraphQLSelector {
    case operationName(String)
    case selector(GraphQLRequest)
}

/// Intercepts GraphQL requests before the get to the try router.
public struct graphQLInterceptor: HBMiddleware {

    typealias GraphQLEndpoint = (selector: GraphQLSelector, response: HTTPResponse)
    let verbose: Bool
    private var mockGraphQLResponses: [GraphQLEndpoint] = []

    public func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {

        let httpRequest = request.asHTTPRequest

        // try and read the incoming request as a GraphQL request.
        guard let incomingGQLRequest = try? GraphQLRequest(request: httpRequest) else {
            return next.respond(to: request)
        }

        // Find the first mock GraphQL response that matches the incoming request.
        if verbose {
            print("👻 Intercepting GraphQL request")
        }
        guard let apiMock = mockGraphQLResponses.first(where: {

            switch $0.selector {

            case .operationName(let operationName):
                return incomingGQLRequest.operations.keys.contains(operationName)

            case .selector(let graphQLSelector):
                return graphQLSelector.matches(incomingGQLRequest)
            }

        }) else {
            print("👻 ⚠️ No mock found for GraphQL request")
            return next.respond(to: request)
        }

        // Use a promise to bridge to the async/await world.
        let promise = request.eventLoop.makePromise(of: HBResponse.self)
        promise.completeWithTask {
            return try await apiMock.response.hbResponse(for: httpRequest, inServerContext: request.application)
        }
        return promise.futureResult
    }
}
