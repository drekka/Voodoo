import Foundation

/// The definition of a mocked endpoint.
public struct RESTEndpoint: Endpoint {
    let method: HTTPMethod
    let path: String
    let response: HTTPResponse
}
