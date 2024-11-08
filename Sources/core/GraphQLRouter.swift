//
//  Created by Derek Clarkson on 4/11/2022.
//

import Foundation
import Hummingbird

/// Router for GraphQL requests.
public class GraphQLRouter {

    private var mockGraphQLResponses: [GraphQLEndpoint] = []

    func add(_ endpoint: GraphQLEndpoint) {
        mockGraphQLResponses.append(endpoint)
    }

    /// Executes for an incoming request.
    ///
    /// This loops through the stored GraphQL endpoints to find a match and execute it for a response.
    public func execute(request: HBRequest) async throws -> HBResponse {
        voodooLog("Intercepting GraphQL request")
        let httpRequest = request.asHTTPRequest
        if let endpoint = try graphQLEndpoint(for: httpRequest) {
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

            case let .operations(operations):
                return operations.allSatisfy { graphQLRequest.operations.keys.contains($0) }

            case let .query(graphQLSelector):
                return graphQLSelector.matches(graphQLRequest)
            }
        }
    }
}
