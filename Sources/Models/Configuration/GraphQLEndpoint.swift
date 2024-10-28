import Foundation

/// The definition of a GraphQL endpoint to be mocked with it's response.
public struct GraphQLEndpoint: Endpoint {
    let method: HTTPMethod
    let selector: GraphQLSelector
    let response: HTTPResponse
}
