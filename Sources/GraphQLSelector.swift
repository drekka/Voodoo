//
//  File.swift
//
//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation
import Hummingbird

/// The available ways a response can be selected for a GraphQL request.
public enum GraphQLSelector {

    /// By matching an operation name in the request.
    case operationName(String)

    /// By matching this graphQL request against the incoming request.
    ///
    /// If this request "matches", ie returns `true` from the ``Matchable.matches(...)``
    /// function then the response is returned.
    case selector(GraphQLRequest)
}

/// Intercepts GraphQL requests before the get to the try router.
public struct GraphQLInterceptor: HBMiddleware {

    typealias GraphQLEndpoint = (selector: GraphQLSelector, response: HTTPResponse)

    private let graphQLPath: String
    private let verbose: Bool

    private var mockGraphQLResponses: [GraphQLEndpoint] = []

    init(path: String, verbose: Bool) {
        graphQLPath = path
        self.verbose = verbose
    }

    public func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {

        // try and read the incoming request as a GraphQL request.
        guard request.uri.path == graphQLPath,
              let incomingGQLRequest = try? GraphQLRequest(request: request.asHTTPRequest) else {
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
            try await apiMock.response.hbResponse(for: request.asHTTPRequest, inServerContext: request.application)
        }
        return promise.futureResult
    }
}
