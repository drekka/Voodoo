//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation
import Hummingbird

/// Intercepts GraphQL requests before the get to the try router.
public class GraphQLRouter {

    private let verbose: Bool

    private var mockGraphQLResponses: [GraphQLEndpoint] = []

    init(verbose: Bool) {
        self.verbose = verbose
    }

    func add(_ endpoint: GraphQLEndpoint) {
        mockGraphQLResponses.append(endpoint)
    }

    public func execute(request: HBRequest) async throws -> HBResponse {
        if self.verbose { print("💀 Intercepting GraphQL request") }
        let httpRequest = request.asHTTPRequest
        if let endpoint = try self.graphQLEndpoint(for: httpRequest) {
            return try await endpoint.response.hbResponse(for: httpRequest, inServerContext: request.application)
        }
        throw VoodooError.noGraphQLEndpoint
    }

    private func graphQLEndpoint(for httpRequest: HTTPRequest) throws -> GraphQLEndpoint? {

        let graphQLRequest = try GraphQLRequest(request: httpRequest)

        return mockGraphQLResponses.first { endpoint in

            // Ensure the methods match.
            guard httpRequest.method == endpoint.method else {
                return false
            }

            // Then check using the endpoint selector to see if it matches the incoming request.
            switch endpoint.selector {

            case .operations(let operations):
                return operations.allSatisfy { graphQLRequest.operations.keys.contains($0) }

            case .query(let graphQLSelector):
                return graphQLSelector.matches(graphQLRequest)
            }
        }
    }
}
